from django.urls import path
from . import views

app_name = 'admin_interface'

urlpatterns = [
    path('', views.dashboard, name='dashboard'),
    path('login/', views.admin_login, name='login'),
    path('logout/', views.admin_logout, name='logout'),
    
    # Gestion des utilisateurs
    path('users/', views.user_list, name='user_list'),
    path('users/create/', views.user_create, name='user_create'),
    path('users/<uuid:user_id>/', views.user_detail, name='user_detail'),
    path('users/<uuid:user_id>/edit/', views.user_edit, name='user_edit'),
    
    # Gestion des rendez-vous
    path('appointments/', views.appointment_list, name='appointment_list'),
    path('appointments/create/', views.appointment_create, name='appointment_create'),
    path('appointments/<uuid:appointment_id>/', views.appointment_detail, name='appointment_detail'),
    path('appointments/<uuid:appointment_id>/edit/', views.appointment_edit, name='appointment_edit'),
    
    # Gestion des consultations
    path('consultations/', views.consultation_list, name='consultation_list'),
    path('consultations/<uuid:consultation_id>/', views.consultation_detail, name='consultation_detail'),
    
    # Gestion des premiers secours
    path('first-aid/modules/', views.first_aid_module_list, name='first_aid_module_list'),
    path('first-aid/modules/create/', views.first_aid_module_create, name='first_aid_module_create'),
    path('first-aid/modules/<uuid:module_id>/', views.first_aid_module_detail, name='first_aid_module_detail'),
    path('first-aid/modules/<uuid:module_id>/edit/', views.first_aid_module_edit, name='first_aid_module_edit'),
    
    # Gestion des contenus
    path('first-aid/modules/<uuid:module_id>/content/create/', views.first_aid_content_create, name='first_aid_content_create'),
    path('first-aid/content/<uuid:content_id>/edit/', views.first_aid_content_edit, name='first_aid_content_edit'),
    path('first-aid/content/<uuid:content_id>/delete/', views.first_aid_content_delete, name='first_aid_content_delete'),
    
    # Gestion des quiz
    path('first-aid/modules/<uuid:module_id>/quiz/create/', views.quiz_create, name='quiz_create'),
    path('first-aid/quiz/<uuid:quiz_id>/edit/', views.quiz_edit, name='quiz_edit'),
    path('first-aid/quiz/<uuid:quiz_id>/questions/', views.quiz_questions, name='quiz_questions'),
    
    # Statistiques et rapports
    path('stats/', views.statistics, name='statistics'),
    path('reports/', views.reports, name='reports'),
]