from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'users', views.UserViewSet)
router.register(r'patients', views.PatientProfileViewSet)
router.register(r'medecins', views.MedecinProfileViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('auth/', include('rest_framework.urls')),
     # API pour récupérer le dossier médical complet d'un patient
   # path('patients/<str:patient_id>/medical-record/', views.PatientMedicalRecordView.as_view(), name='patient-medical-record'),
    
    # API pour récupérer uniquement les antécédents médicaux
    #path('patients/<str:patient_id>/medical-history/', views.PatientMedicalHistoryView.as_view(), name='patient-medical-history'),
    
    path('register/', views.UserRegistrationView.as_view(), name='register'),
    path('patient/dashboard/', views.PatientDashboardView.as_view(), name='patient-dashboard'),
    path('medecin/dashboard/', views.MedecinDashboardView.as_view(), name='medecin-dashboard'),
    path('user/profile/', views.UserProfileView.as_view(), name='user-profile'),
    path('patient/appointments/', views.PatientAppointmentsView.as_view(), name='patient-appointments'),
    path('medecin/appointments/', views.MedecinAppointmentsView.as_view(), name='medecin-appointments'),
    path('consultations/', include('consultations.urls', namespace='consultations')),
    path('first-aid/', include('premiers_secours.urls', namespace='premiers_secours')),
]
