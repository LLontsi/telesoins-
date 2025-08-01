from rest_framework import viewsets, permissions, status, filters, generics
from rest_framework.response import Response
from rest_framework.decorators import action
from django.utils import timezone
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.db.models import Q, Count, Avg
from accounts.models import User, PatientProfile, MedecinProfile
from consultations.models import Appointment, Consultation, Prescription, Message
from premiers_secours.models import FirstAidModule, FirstAidContent, Quiz, QuizQuestion, UserQuizResult
from .serializers import (
    UserSerializer, UserRegistrationSerializer, PatientProfileSerializer, 
    MedecinProfileSerializer, AppointmentSerializer, ConsultationSerializer, 
    PrescriptionSerializer, MessageSerializer, FirstAidModuleSerializer, 
    FirstAidContentSerializer, QuizSerializer, UserQuizResultSerializer
)
from .permissions import IsOwnerOrReadOnly, IsMedecin, IsPatient

class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = [permissions.AllowAny]
    serializer_class = UserRegistrationSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]
    
    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def me(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
    
    @action(detail=False, methods=['put'], permission_classes=[permissions.IsAuthenticated])
    def update_profile(self, request):
        user = request.user
        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PatientProfileViewSet(viewsets.ModelViewSet):
    queryset = PatientProfile.objects.all()
    serializer_class = PatientProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return PatientProfile.objects.all()
        elif user.role == 'medecin':
            # Médecins ne voient que les profils de leurs patients
            patient_ids = Consultation.objects.filter(medecin=user).values_list('patient', flat=True)
            return PatientProfile.objects.filter(user__id__in=patient_ids)
        else:
            # Les patients ne voient que leur propre profil
            return PatientProfile.objects.filter(user=user)

class MedecinProfileViewSet(viewsets.ModelViewSet):
    queryset = MedecinProfile.objects.all()
    serializer_class = MedecinProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return MedecinProfile.objects.all()
        elif user.role == 'patient':
            # Patients ne voient que les profils de leurs médecins
            medecin_ids = Consultation.objects.filter(patient=user).values_list('medecin', flat=True)
            return MedecinProfile.objects.filter(user__id__in=medecin_ids)
        else:
            # Les médecins ne voient que leur propre profil
            return MedecinProfile.objects.filter(user=user)

class AppointmentViewSet(viewsets.ModelViewSet):
    queryset = Appointment.objects.all()
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['status', 'is_urgent', 'datetime']
    search_fields = ['reason', 'notes']
    ordering_fields = ['datetime', 'created_at', 'updated_at']
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return Appointment.objects.all()
        elif user.role == 'medecin':
            return Appointment.objects.filter(medecin=user)
        else:
            return Appointment.objects.filter(patient=user)
    
    def perform_create(self, serializer):
        # Si c'est un patient qui crée le RDV, on le définit automatiquement comme patient
        if self.request.user.role == 'patient':
            serializer.save(patient=self.request.user)
        else:
            serializer.save()

class ConsultationViewSet(viewsets.ModelViewSet):
    queryset = Consultation.objects.all()
    serializer_class = ConsultationSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['type']
    search_fields = ['summary', 'diagnosis']
    ordering_fields = ['start_time', 'end_time']
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return Consultation.objects.all()
        elif user.role == 'medecin':
            return Consultation.objects.filter(medecin=user)
        else:
            return Consultation.objects.filter(patient=user)

class PrescriptionViewSet(viewsets.ModelViewSet):
    queryset = Prescription.objects.all()
    serializer_class = PrescriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return Prescription.objects.all()
        elif user.role == 'medecin':
            return Prescription.objects.filter(consultation__medecin=user)
        else:
            return Prescription.objects.filter(consultation__patient=user)
    
    def perform_create(self, serializer):
        # Vérifier que le médecin est bien celui qui a fait la consultation
        consultation = get_object_or_404(Consultation, pk=self.request.data.get('consultation'))
        if self.request.user.role == 'medecin' and consultation.medecin == self.request.user:
            serializer.save()
        else:
            raise permissions.PermissionDenied("Vous n'avez pas l'autorisation de créer une prescription pour cette consultation.")

class MessageViewSet(viewsets.ModelViewSet):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return Message.objects.all()
        return Message.objects.filter(
            Q(consultation__patient=user) | 
            Q(consultation__medecin=user)
        )
    
    def perform_create(self, serializer):
        # Vérifier que l'utilisateur participe à la consultation
        consultation = get_object_or_404(Consultation, pk=self.request.data.get('consultation'))
        if consultation.patient == self.request.user or consultation.medecin == self.request.user:
            serializer.save(sender=self.request.user)
        else:
            raise permissions.PermissionDenied("Vous n'avez pas l'autorisation d'envoyer un message dans cette consultation.")

class FirstAidModuleViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = FirstAidModule.objects.filter(is_published=True)
    serializer_class = FirstAidModuleSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['category', 'difficulty_level']
    search_fields = ['title', 'description']
    ordering_fields = ['order', 'title', 'created_at']

class FirstAidContentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = FirstAidContent.objects.all()
    serializer_class = FirstAidContentSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['content_type', 'module']
    ordering_fields = ['order']

class QuizViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Quiz.objects.all()
    serializer_class = QuizSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['module']
    search_fields = ['title', 'description']
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def submit_answers(self, request, pk=None):
        quiz = self.get_object()
        answers = request.data.get('answers', {})
        
        # Calcul du score
        total_questions = quiz.questions.count()
        if total_questions == 0:
            return Response({"error": "Ce quiz ne contient aucune question."}, status=status.HTTP_400_BAD_REQUEST)
        
        correct_answers = 0
        
        for question_id, selected_option_id in answers.items():
            try:
                question = QuizQuestion.objects.get(pk=question_id, quiz=quiz)
                correct_option = question.options.filter(is_correct=True).first()
                
                if correct_option and str(correct_option.id) == selected_option_id:
                    correct_answers += 1
            except QuizQuestion.DoesNotExist:
                pass
        
        score = int((correct_answers / total_questions) * 100)
        passed = score >= quiz.passing_score
        
        # Enregistrement du résultat
        result, created = UserQuizResult.objects.update_or_create(
            user=request.user,
            quiz=quiz,
            defaults={
                'score': score,
                'passed': passed
            }
        )
        
        serializer = UserQuizResultSerializer(result)
        return Response(serializer.data)

class UserQuizResultViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = UserQuizResult.objects.all()
    serializer_class = UserQuizResultSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return UserQuizResult.objects.all()
        return UserQuizResult.objects.filter(user=user)

class UserProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        user = request.user
        user_data = UserSerializer(user).data
        
        if user.role == 'patient' and hasattr(user, 'patient_profile'):
            profile_data = PatientProfileSerializer(user.patient_profile).data
            return Response({**user_data, 'profile': profile_data})
        elif user.role == 'medecin' and hasattr(user, 'medecin_profile'):
            profile_data = MedecinProfileSerializer(user.medecin_profile).data
            return Response({**user_data, 'profile': profile_data})
        else:
            return Response(user_data)
    
    def put(self, request):
        user = request.user
        user_serializer = UserSerializer(user, data=request.data, partial=True)
        
        if user_serializer.is_valid():
            user_serializer.save()
            
            if 'profile' in request.data:
                profile_data = request.data['profile']
                
                if user.role == 'patient' and hasattr(user, 'patient_profile'):
                    profile_serializer = PatientProfileSerializer(user.patient_profile, data=profile_data, partial=True)
                    if profile_serializer.is_valid():
                        profile_serializer.save()
                    else:
                        return Response(profile_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
                elif user.role == 'medecin' and hasattr(user, 'medecin_profile'):
                    profile_serializer = MedecinProfileSerializer(user.medecin_profile, data=profile_data, partial=True)
                    if profile_serializer.is_valid():
                        profile_serializer.save()
                    else:
                        return Response(profile_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
            return Response(UserSerializer(user).data)
        return Response(user_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PatientDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsPatient]
    
    def get(self, request):
        user = request.user
        
        # Prochains rendez-vous
        upcoming_appointments = Appointment.objects.filter(
            patient=user, 
            datetime__gt=timezone.now(),
            status__in=['pending', 'confirmed']
        ).order_by('datetime')[:5]
        
        # Consultations récentes
        recent_consultations = Consultation.objects.filter(
            patient=user
        ).order_by('-start_time')[:5]
        
        # Prescriptions actives
        active_prescriptions = Prescription.objects.filter(
            Q(consultation__patient=user) & 
            (Q(valid_until__gt=timezone.now()) | Q(valid_until=None))
        ).order_by('-created_at')
        
        # Progression premiers secours
        quiz_results = UserQuizResult.objects.filter(user=user)
        
        return Response({
            'upcoming_appointments': AppointmentSerializer(upcoming_appointments, many=True).data,
            'recent_consultations': ConsultationSerializer(recent_consultations, many=True).data,
            'active_prescriptions': PrescriptionSerializer(active_prescriptions, many=True).data,
            'quiz_results': UserQuizResultSerializer(quiz_results, many=True).data,
        })

class MedecinDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsMedecin]
    
    def get(self, request):
        user = request.user
        
        # Rendez-vous du jour
        today = timezone.now().date()
        today_appointments = Appointment.objects.filter(
            medecin=user,
            datetime__date=today,
            status__in=['pending', 'confirmed']
        ).order_by('datetime')
        
        # Consultations en attente
        pending_consultations = Consultation.objects.filter(
            medecin=user,
            end_time=None
        ).order_by('-start_time')
        
        # Statistiques
        total_appointments = Appointment.objects.filter(medecin=user).count()
        total_consultations = Consultation.objects.filter(medecin=user).count()
        total_patients = Consultation.objects.filter(medecin=user).values('patient').distinct().count()
        
        return Response({
            'today_appointments': AppointmentSerializer(today_appointments, many=True).data,
            'pending_consultations': ConsultationSerializer(pending_consultations, many=True).data,
            'stats': {
                'total_appointments': total_appointments,
                'total_consultations': total_consultations,
                'total_patients': total_patients,
            }
        })

class PatientAppointmentsView(generics.ListAPIView):
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated, IsPatient]
    
    def get_queryset(self):
        return Appointment.objects.filter(patient=self.request.user)

class MedecinAppointmentsView(generics.ListAPIView):
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated, IsMedecin]
    
    def get_queryset(self):
        return Appointment.objects.filter(medecin=self.request.user)