from django.contrib import admin

# Register your models here.
from django.contrib import admin
from .models import Appointment, Consultation, Prescription, Message

class PrescriptionInline(admin.TabularInline):
    model = Prescription
    extra = 0

class MessageInline(admin.TabularInline):
    model = Message
    extra = 0
    readonly_fields = ('timestamp',)

@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('patient', 'medecin', 'datetime', 'status', 'is_urgent')
    list_filter = ('status', 'is_urgent', 'datetime')
    search_fields = ('patient__email', 'patient__first_name', 'medecin__email', 'medecin__first_name', 'reason')
    date_hierarchy = 'datetime'

@admin.register(Consultation)
class ConsultationAdmin(admin.ModelAdmin):
    list_display = ('patient', 'medecin', 'type', 'start_time', 'end_time')
    list_filter = ('type', 'start_time')
    search_fields = ('patient__email', 'patient__first_name', 'medecin__email', 'medecin__first_name', 'summary', 'diagnosis')
    inlines = [PrescriptionInline, MessageInline]

@admin.register(Prescription)
class PrescriptionAdmin(admin.ModelAdmin):
    list_display = ('consultation', 'created_at', 'valid_until')
    search_fields = ('consultation__patient__email', 'consultation__patient__first_name', 'details')
    date_hierarchy = 'created_at'

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('sender', 'consultation', 'timestamp', 'is_read')
    list_filter = ('is_read', 'timestamp')
    search_fields = ('sender__email', 'content', 'consultation__patient__email')
    date_hierarchy = 'timestamp'