from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'appointments', views.AppointmentViewSet)
router.register(r'consultations', views.ConsultationViewSet)
router.register(r'prescriptions', views.PrescriptionViewSet)
router.register(r'messages', views.MessageViewSet)

app_name = 'consultations'

urlpatterns = [
    path('', include(router.urls)),
]