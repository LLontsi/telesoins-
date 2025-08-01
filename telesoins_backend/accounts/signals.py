from django.db.models.signals import post_save
from django.dispatch import receiver
from django.conf import settings
from rest_framework.authtoken.models import Token
from .models import User, PatientProfile, MedecinProfile

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        # Création du profil en fonction du rôle
        if instance.role == 'patient':
            PatientProfile.objects.create(user=instance)
        elif instance.role == 'medecin':
            MedecinProfile.objects.create(user=instance)
        
        # Création du token d'authentification
        Token.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    # Mise à jour du profil en fonction du rôle
    if instance.role == 'patient' and not hasattr(instance, 'patient_profile'):
        PatientProfile.objects.create(user=instance)
    elif instance.role == 'medecin' and not hasattr(instance, 'medecin_profile'):
        MedecinProfile.objects.create(user=instance)
    
    if instance.role == 'patient' and hasattr(instance, 'patient_profile'):
        instance.patient_profile.save()
    elif instance.role == 'medecin' and hasattr(instance, 'medecin_profile'):
        instance.medecin_profile.save()