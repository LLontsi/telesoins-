from django.db import models

# Create your models here.
from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.utils.translation import gettext_lazy as _
import uuid

class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('L\'adresse email est obligatoire')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('role', 'admin')
        
        return self.create_user(email, password, **extra_fields)

class User(AbstractUser):
    ROLE_CHOICES = (
        ('patient', 'Patient'),
        ('medecin', 'Médecin'),
        ('admin', 'Administrateur'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = None
    email = models.EmailField(_('adresse e-mail'), unique=True)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='patient')
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    profile_photo = models.ImageField(upload_to='profile_photos/', blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []
    
    objects = UserManager()
    
    def __str__(self):
        return f"{self.email} ({self.get_role_display()})"
    
    def has_role(self, role):
        return self.role == role

class PatientProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='patient_profile')
    date_of_birth = models.DateField(blank=True, null=True)
    emergency_contacts = models.JSONField(default=dict, blank=True)
    medical_history = models.TextField(blank=True)
    allergies = models.TextField(blank=True)
    blood_type = models.CharField(max_length=10, blank=True, null=True)
    first_aid_progress = models.JSONField(default=dict, blank=True)
    
    def __str__(self):
        return f"Profil patient de {self.user.email}"

class MedecinProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='medecin_profile')
    speciality = models.CharField(max_length=100)
    licence_number = models.CharField(max_length=50, unique=True)
    years_of_experience = models.PositiveIntegerField(default=0)
    available_hours = models.JSONField(default=dict, blank=True)
    triage_protocols = models.JSONField(default=dict, blank=True)
    
    def __str__(self):
        return f"Profil médecin de {self.user.email} - {self.speciality}"