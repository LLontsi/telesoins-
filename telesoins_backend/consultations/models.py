from django.db import models

# Create your models here.
from django.db import models
import uuid
from accounts.models import User

class Appointment(models.Model):
    STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('confirmed', 'Confirmé'),
        ('canceled', 'Annulé'),
        ('completed', 'Terminé'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='patient_appointments')
    medecin = models.ForeignKey(User, on_delete=models.CASCADE, related_name='medecin_appointments')
    datetime = models.DateTimeField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    reason = models.TextField()
    notes = models.TextField(blank=True)
    is_urgent = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-datetime']
        verbose_name = "Rendez-vous"
        verbose_name_plural = "Rendez-vous"
    
    def __str__(self):
        return f"RDV: {self.patient.get_full_name()} avec {self.medecin.get_full_name()} le {self.datetime.strftime('%d/%m/%Y %H:%M')}"

class Consultation(models.Model):
    TYPE_CHOICES = (
        ('video', 'Vidéo'),
        ('message', 'Message'),
        ('sms', 'SMS'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    appointment = models.OneToOneField(Appointment, on_delete=models.CASCADE, related_name='consultation', null=True, blank=True)
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='patient_consultations')
    medecin = models.ForeignKey(User, on_delete=models.CASCADE, related_name='medecin_consultations')
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    start_time = models.DateTimeField(auto_now_add=True)
    end_time = models.DateTimeField(null=True, blank=True)
    summary = models.TextField(blank=True)
    diagnosis = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-start_time']
        verbose_name = "Consultation"
        verbose_name_plural = "Consultations"
    
    def __str__(self):
        return f"Consultation {self.get_type_display()}: {self.patient.get_full_name()} avec {self.medecin.get_full_name()}"

class Prescription(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    consultation = models.ForeignKey(Consultation, on_delete=models.CASCADE, related_name='prescriptions')
    details = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    valid_until = models.DateField(null=True, blank=True)
    
    class Meta:
        verbose_name = "Prescription"
        verbose_name_plural = "Prescriptions"
    
    def __str__(self):
        return f"Prescription pour {self.consultation.patient.get_full_name()}"

class Message(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    consultation = models.ForeignKey(Consultation, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages')
    content = models.TextField()
    attachment = models.FileField(upload_to='message_attachments/', null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['timestamp']
        verbose_name = "Message"
        verbose_name_plural = "Messages"
    
    def __str__(self):
        return f"Message de {self.sender.get_full_name()} - {self.timestamp.strftime('%d/%m/%Y %H:%M')}"