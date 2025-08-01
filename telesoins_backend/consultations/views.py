from django.shortcuts import render

# Create your views here.
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import viewsets, permissions, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q

from .models import Appointment, Consultation, Prescription, Message
from accounts.models import User
from api.serializers import (
    AppointmentSerializer, ConsultationSerializer, 
    PrescriptionSerializer, MessageSerializer
)

class AppointmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les rendez-vous.
    Les patients ne peuvent voir et modifier que leurs propres rendez-vous.
    Les médecins ne peuvent voir et modifier que les rendez-vous qui leur sont assignés.
    """
    queryset = Appointment.objects.all()
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['reason', 'notes', 'patient__first_name', 'patient__last_name', 
                     'medecin__first_name', 'medecin__last_name']
    ordering_fields = ['datetime', 'created_at', 'status', 'is_urgent']
    ordering = ['-datetime']

    def get_queryset(self):
        """
        Filtrer les rendez-vous en fonction du rôle de l'utilisateur.
        """
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return Appointment.objects.all()
        elif user.role == 'medecin':
            return Appointment.objects.filter(medecin=user)
        else:  # patient
            return Appointment.objects.filter(patient=user)

    def perform_create(self, serializer):
        """
        Si l'utilisateur est un patient, le définir automatiquement comme patient du rendez-vous.
        """
        if self.request.user.role == 'patient':
            serializer.save(patient=self.request.user)
        else:
            serializer.save()

    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """
        Mettre à jour le statut d'un rendez-vous.
        """
        appointment = self.get_object()
        status_value = request.data.get('status')
        
        if not status_value or status_value not in dict(Appointment.STATUS_CHOICES).keys():
            return Response(
                {"error": "Statut invalide."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        appointment.status = status_value
        appointment.save()
        
        return Response(AppointmentSerializer(appointment).data)

    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        """
        Récupérer les prochains rendez-vous.
        """
        queryset = self.get_queryset().filter(
            datetime__gt=timezone.now(),
            status__in=['pending', 'confirmed']
        ).order_by('datetime')
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_date(self, request):
        """
        Récupérer les rendez-vous pour une date spécifique.
        """
        date_str = request.query_params.get('date')
        if not date_str:
            return Response(
                {"error": "Le paramètre date est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Convertir la date au format YYYY-MM-DD
            from datetime import datetime
            date_obj = datetime.strptime(date_str, '%Y-%m-%d').date()
            
            queryset = self.get_queryset().filter(
                datetime__date=date_obj
            ).order_by('datetime')
            
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data)
        except ValueError:
            return Response(
                {"error": "Format de date invalide. Utilisez YYYY-MM-DD."},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['get'])
    def urgent(self, request):
        """
        Récupérer les rendez-vous urgents.
        """
        queryset = self.get_queryset().filter(is_urgent=True).order_by('datetime')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

class ConsultationViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les consultations.
    Les patients ne peuvent voir que leurs propres consultations.
    Les médecins ne peuvent voir que les consultations qu'ils ont menées.
    """
    queryset = Consultation.objects.all()
    serializer_class = ConsultationSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['summary', 'diagnosis', 'patient__first_name', 'patient__last_name', 
                     'medecin__first_name', 'medecin__last_name']
    ordering_fields = ['start_time', 'end_time', 'type']
    ordering = ['-start_time']

    def get_queryset(self):
        """
        Filtrer les consultations en fonction du rôle de l'utilisateur.
        """
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return Consultation.objects.all()
        elif user.role == 'medecin':
            return Consultation.objects.filter(medecin=user)
        else:  # patient
            return Consultation.objects.filter(patient=user)

    def perform_create(self, serializer):
        """
        Si l'utilisateur est un médecin, le définir automatiquement comme médecin de la consultation.
        """
        if self.request.user.role == 'medecin':
            serializer.save(medecin=self.request.user)
        else:
            serializer.save()

    @action(detail=True, methods=['post'])
    def end_consultation(self, request, pk=None):
        """
        Terminer une consultation en définissant end_time.
        """
        consultation = self.get_object()
        
        if consultation.end_time:
            return Response(
                {"error": "Cette consultation est déjà terminée."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        consultation.end_time = timezone.now()
        if 'summary' in request.data:
            consultation.summary = request.data['summary']
        if 'diagnosis' in request.data:
            consultation.diagnosis = request.data['diagnosis']
        
        consultation.save()
        
        # Si la consultation est liée à un rendez-vous, mettre à jour son statut
        if consultation.appointment:
            consultation.appointment.status = 'completed'
            consultation.appointment.save()
        
        return Response(ConsultationSerializer(consultation).data)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """
        Récupérer les consultations actives (non terminées).
        """
        queryset = self.get_queryset().filter(end_time=None).order_by('-start_time')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        """
        Récupérer les consultations filtrées par type.
        """
        type_value = request.query_params.get('type')
        if not type_value or type_value not in dict(Consultation.TYPE_CHOICES).keys():
            return Response(
                {"error": "Type invalide."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        queryset = self.get_queryset().filter(type=type_value).order_by('-start_time')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """
        Récupérer tous les messages d'une consultation spécifique.
        """
        consultation = self.get_object()
        messages = Message.objects.filter(consultation=consultation).order_by('timestamp')
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def prescriptions(self, request, pk=None):
        """
        Récupérer toutes les prescriptions d'une consultation spécifique.
        """
        consultation = self.get_object()
        prescriptions = Prescription.objects.filter(consultation=consultation).order_by('-created_at')
        serializer = PrescriptionSerializer(prescriptions, many=True)
        return Response(serializer.data)

class PrescriptionViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les prescriptions.
    Les patients ne peuvent voir que leurs propres prescriptions.
    Les médecins ne peuvent voir et modifier que les prescriptions des consultations qu'ils ont menées.
    """
    queryset = Prescription.objects.all()
    serializer_class = PrescriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['created_at', 'valid_until']
    ordering = ['-created_at']

    def get_queryset(self):
        """
        Filtrer les prescriptions en fonction du rôle de l'utilisateur.
        """
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return Prescription.objects.all()
        elif user.role == 'medecin':
            return Prescription.objects.filter(consultation__medecin=user)
        else:  # patient
            return Prescription.objects.filter(consultation__patient=user)

    def perform_create(self, serializer):
        """
        Vérifier que l'utilisateur est bien le médecin de la consultation.
        """
        consultation_id = self.request.data.get('consultation')
        if not consultation_id:
            return Response(
                {"error": "L'ID de consultation est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        consultation = get_object_or_404(Consultation, pk=consultation_id)
        
        if self.request.user.role != 'medecin' or consultation.medecin != self.request.user:
            return Response(
                {"error": "Vous n'êtes pas autorisé à créer une prescription pour cette consultation."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer.save()

    @action(detail=False, methods=['get'])
    def active(self, request):
        """
        Récupérer les prescriptions actives (valides aujourd'hui ou sans date de fin).
        """
        today = timezone.now().date()
        queryset = self.get_queryset().filter(
            Q(valid_until__gte=today) | Q(valid_until=None)
        ).order_by('-created_at')
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_patient(self, request):
        """
        Récupérer les prescriptions filtrées par patient (pour les médecins).
        """
        if request.user.role != 'medecin' and not request.user.is_staff and request.user.role != 'admin':
            return Response(
                {"error": "Accès non autorisé."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        patient_id = request.query_params.get('patient_id')
        if not patient_id:
            return Response(
                {"error": "Le paramètre patient_id est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        queryset = self.get_queryset().filter(
            consultation__patient__id=patient_id
        ).order_by('-created_at')
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

class MessageViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les messages.
    Les utilisateurs ne peuvent voir et modifier que les messages des consultations auxquelles ils participent.
    """
    queryset = Message.objects.all()
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['timestamp']
    ordering = ['timestamp']

    def get_queryset(self):
        """
        Filtrer les messages en fonction de l'utilisateur.
        """
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return Message.objects.all()
        
        return Message.objects.filter(
            Q(consultation__patient=user) | Q(consultation__medecin=user)
        )

    def perform_create(self, serializer):
        """
        Vérifier que l'utilisateur participe à la consultation et le définir comme expéditeur.
        """
        consultation_id = self.request.data.get('consultation')
        if not consultation_id:
            return Response(
                {"error": "L'ID de consultation est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        consultation = get_object_or_404(Consultation, pk=consultation_id)
        
        if consultation.patient != self.request.user and consultation.medecin != self.request.user:
            return Response(
                {"error": "Vous n'êtes pas autorisé à envoyer un message dans cette consultation."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer.save(sender=self.request.user)

    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """
        Marquer un message comme lu.
        """
        message = self.get_object()
        
        if message.is_read:
            return Response({"status": "Le message est déjà marqué comme lu."})
        
        message.is_read = True
        message.save()
        
        return Response({"status": "Message marqué comme lu."})

    @action(detail=False, methods=['post'])
    def mark_all_as_read(self, request):
        """
        Marquer tous les messages d'une consultation comme lus.
        """
        consultation_id = request.data.get('consultation')
        if not consultation_id:
            return Response(
                {"error": "L'ID de consultation est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        consultation = get_object_or_404(Consultation, pk=consultation_id)
        
        # Vérifier que l'utilisateur participe à la consultation
        if consultation.patient != request.user and consultation.medecin != request.user:
            return Response(
                {"error": "Vous n'êtes pas autorisé à accéder à cette consultation."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Ne marquer comme lus que les messages envoyés par l'autre personne
        if request.user == consultation.patient:
            Message.objects.filter(
                consultation=consultation,
                sender=consultation.medecin,
                is_read=False
            ).update(is_read=True)
        else:
            Message.objects.filter(
                consultation=consultation,
                sender=consultation.patient,
                is_read=False
            ).update(is_read=True)
        
        return Response({"status": "Tous les messages ont été marqués comme lus."})

    @action(detail=False, methods=['get'])
    def unread(self, request):
        """
        Récupérer les messages non lus.
        """
        queryset = self.get_queryset().filter(
        Q(is_read=False) & ~Q(sender=request.user)
    ).order_by('timestamp')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_consultation(self, request):
        """
        Récupérer les messages filtrés par consultation.
        """
        consultation_id = request.query_params.get('consultation_id')
        if not consultation_id:
            return Response(
                {"error": "Le paramètre consultation_id est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        consultation = get_object_or_404(Consultation, pk=consultation_id)
        
        # Vérifier que l'utilisateur participe à la consultation
        if consultation.patient != request.user and consultation.medecin != request.user and not request.user.is_staff and request.user.role != 'admin':
            return Response(
                {"error": "Vous n'êtes pas autorisé à accéder à cette consultation."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        queryset = Message.objects.filter(consultation=consultation).order_by('timestamp')
        serializer = self.get_serializer(queryset, many=True)
        
        return Response(serializer.data)