from django.shortcuts import render

# Create your views here.
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib import messages
from django.db.models import Count, Avg, Q
from django.utils import timezone
from django.http import JsonResponse
from django.core.paginator import Paginator

from accounts.models import User, PatientProfile, MedecinProfile
from consultations.models import Appointment, Consultation, Prescription, Message
from premiers_secours.models import FirstAidModule, FirstAidContent, Quiz, QuizQuestion, QuizOption, UserQuizResult

from .forms import (
    LoginForm, UserForm, PatientProfileForm, MedecinProfileForm, 
    AppointmentForm, ConsultationFilterForm, FirstAidModuleForm,
    FirstAidContentForm, QuizForm, QuizQuestionForm, QuizOptionFormSet, QuizQuestionFormSet
)

# Vérification si l'utilisateur est administrateur
def is_admin(user):
    return user.is_staff or user.role == 'admin'

# Page de connexion
def admin_login(request):
    if request.user.is_authenticated and is_admin(request.user):
        return redirect('admin_interface:dashboard')
    
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            password = form.cleaned_data['password']
            user = authenticate(request, username=email, password=password)
            
            if user is not None and is_admin(user):
                login(request, user)
                return redirect('admin_interface:dashboard')
            else:
                messages.error(request, "Identifiants invalides ou vous n'avez pas les permissions d'administrateur.")
    else:
        form = LoginForm()
    
    return render(request, 'admin_interface/login.html', {'form': form})

# Déconnexion
@login_required
def admin_logout(request):
    logout(request)
    return redirect('admin_interface:login')

# Tableau de bord
@login_required
@user_passes_test(is_admin)
def dashboard(request):
    # Statistiques générales
    total_patients = User.objects.filter(role='patient').count()
    total_medecins = User.objects.filter(role='medecin').count()
    total_appointments = Appointment.objects.count()
    total_consultations = Consultation.objects.count()
    
    # Rendez-vous aujourd'hui
    today = timezone.now().date()
    today_appointments = Appointment.objects.filter(datetime__date=today)
    
    # Consultations récentes
    recent_consultations = Consultation.objects.all().order_by('-start_time')[:10]
    
    # Statistiques d'utilisation
    monthly_stats = Consultation.objects.extra(select={
        'month': "EXTRACT(month FROM start_time)",
        'year': "EXTRACT(year FROM start_time)"
    }).values('month', 'year').annotate(count=Count('id')).order_by('year', 'month')
    
    context = {
        'total_patients': total_patients,
        'total_medecins': total_medecins,
        'total_appointments': total_appointments,
        'total_consultations': total_consultations,
        'today_appointments': today_appointments,
        'recent_consultations': recent_consultations,
        'monthly_stats': monthly_stats,
    }
    
    return render(request, 'admin_interface/dashboard.html', context)

# Gestion des utilisateurs
@login_required
@user_passes_test(is_admin)
def user_list(request):
    users = User.objects.all().order_by('-date_joined')
    
    # Filtrage
    role = request.GET.get('role')
    search = request.GET.get('search')
    
    if role:
        users = users.filter(role=role)
    
    if search:
        users = users.filter(
            Q(email__icontains=search) | 
            Q(first_name__icontains=search) | 
            Q(last_name__icontains=search)
        )
    
    # Pagination
    paginator = Paginator(users, 15)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'page_obj': page_obj,
        'role': role,
        'search': search,
    }
    
    return render(request, 'admin_interface/utilisateurs/liste.html', context)

@login_required
@user_passes_test(is_admin)
def user_detail(request, user_id):
    user = get_object_or_404(User, id=user_id)
    
    # Récupérer des informations supplémentaires en fonction du rôle
    if user.role == 'patient':
        profile = PatientProfile.objects.filter(user=user).first()
        appointments = Appointment.objects.filter(patient=user).order_by('-datetime')
        consultations = Consultation.objects.filter(patient=user).order_by('-start_time')
    elif user.role == 'medecin':
        profile = MedecinProfile.objects.filter(user=user).first()
        appointments = Appointment.objects.filter(medecin=user).order_by('-datetime')
        consultations = Consultation.objects.filter(medecin=user).order_by('-start_time')
    else:
        profile = None
        appointments = []
        consultations = []
    
    context = {
        'user_obj': user,
        'profile': profile,
        'appointments': appointments,
        'consultations': consultations,
    }
    
    return render(request, 'admin_interface/users/detail.html', context)

@login_required
@user_passes_test(is_admin)
def user_create(request):
    if request.method == 'POST':
        user_form = UserForm(request.POST, request.FILES)
        
        if user_form.is_valid():
            user = user_form.save()
            
            messages.success(request, f"L'utilisateur {user.email} a été créé avec succès.")
            return redirect('admin_interface:user_detail', user_id=user.id)
    else:
        user_form = UserForm()
    
    context = {
        'user_form': user_form,
        'title': 'Créer un utilisateur',
    }
    
    return render(request, 'admin_interface/users/form.html', context)

@login_required
@user_passes_test(is_admin)
def user_edit(request, user_id):
    user = get_object_or_404(User, id=user_id)
    
    if request.method == 'POST':
        user_form = UserForm(request.POST, request.FILES, instance=user)
        
        # Formulaires de profil spécifiques au rôle
        if user.role == 'patient' and hasattr(user, 'patient_profile'):
            profile_form = PatientProfileForm(request.POST, instance=user.patient_profile)
        elif user.role == 'medecin' and hasattr(user, 'medecin_profile'):
            profile_form = MedecinProfileForm(request.POST, instance=user.medecin_profile)
        else:
            profile_form = None
        
        if user_form.is_valid() and (profile_form is None or profile_form.is_valid()):
            user = user_form.save()
            
            if profile_form:
                profile_form.save()
            
            messages.success(request, f"L'utilisateur {user.email} a été mis à jour avec succès.")
            return redirect('admin_interface:user_detail', user_id=user.id)
    else:
        user_form = UserForm(instance=user)
        
        # Formulaires de profil spécifiques au rôle
        if user.role == 'patient' and hasattr(user, 'patient_profile'):
            profile_form = PatientProfileForm(instance=user.patient_profile)
        elif user.role == 'medecin' and hasattr(user, 'medecin_profile'):
            profile_form = MedecinProfileForm(instance=user.medecin_profile)
        else:
            profile_form = None
    
    context = {
        'user_form': user_form,
        'profile_form': profile_form,
        'user_obj': user,
        'title': 'Modifier un utilisateur',
    }
    
    return render(request, 'admin_interface/users/form.html', context)

# Gestion des rendez-vous
@login_required
@user_passes_test(is_admin)
def appointment_list(request):
    appointments = Appointment.objects.all().order_by('-datetime')
    
    # Filtrage
    status = request.GET.get('status')
    is_urgent = request.GET.get('is_urgent')
    search = request.GET.get('search')
    
    if status:
        appointments = appointments.filter(status=status)
    
    if is_urgent:
        appointments = appointments.filter(is_urgent=True)
    
    if search:
        appointments = appointments.filter(
            Q(patient__email__icontains=search) | 
            Q(patient__first_name__icontains=search) | 
            Q(patient__last_name__icontains=search) |
            Q(medecin__email__icontains=search) | 
            Q(medecin__first_name__icontains=search) | 
            Q(medecin__last_name__icontains=search) |
            Q(reason__icontains=search)
        )
    
    # Pagination
    paginator = Paginator(appointments, 15)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'page_obj': page_obj,
        'status': status,
        'is_urgent': is_urgent,
        'search': search,
    }
    
    return render(request, 'admin_interface/rendez-vous/liste.html', context)

@login_required
@user_passes_test(is_admin)
def appointment_detail(request, appointment_id):
    appointment = get_object_or_404(Appointment, id=appointment_id)
    consultation = Consultation.objects.filter(appointment=appointment).first()
    
    context = {
        'appointment': appointment,
        'consultation': consultation,
    }
    
    return render(request, 'admin_interface/appointments/detail.html', context)

@login_required
@user_passes_test(is_admin)
def appointment_create(request):
    if request.method == 'POST':
        form = AppointmentForm(request.POST)
        if form.is_valid():
            appointment = form.save()
            messages.success(request, "Le rendez-vous a été créé avec succès.")
            return redirect('admin_interface:appointment_detail', appointment_id=appointment.id)
    else:
        form = AppointmentForm()
    
    context = {
        'form': form,
        'title': 'Créer un rendez-vous',
    }
    
    return render(request, 'admin_interface/appointments/form.html', context)

@login_required
@user_passes_test(is_admin)
def appointment_edit(request, appointment_id):
    appointment = get_object_or_404(Appointment, id=appointment_id)
    
    if request.method == 'POST':
        form = AppointmentForm(request.POST, instance=appointment)
        if form.is_valid():
            appointment = form.save()
            messages.success(request, "Le rendez-vous a été mis à jour avec succès.")
            return redirect('admin_interface:appointment_detail', appointment_id=appointment.id)
    else:
        form = AppointmentForm(instance=appointment)
    
    context = {
        'form': form,
        'appointment': appointment,
        'title': 'Modifier un rendez-vous',
    }
    
    return render(request, 'admin_interface/appointments/form.html', context)

# Gestion des consultations
@login_required
@user_passes_test(is_admin)
def consultation_list(request):
    consultations = Consultation.objects.all().order_by('-start_time')
    
    # Filtrage avec le formulaire
    form = ConsultationFilterForm(request.GET)
    if form.is_valid():
        if form.cleaned_data.get('start_date'):
            consultations = consultations.filter(start_time__date__gte=form.cleaned_data['start_date'])
        
        if form.cleaned_data.get('end_date'):
            consultations = consultations.filter(start_time__date__lte=form.cleaned_data['end_date'])
        
        if form.cleaned_data.get('type'):
            consultations = consultations.filter(type=form.cleaned_data['type'])
        
        if form.cleaned_data.get('medecin'):
            consultations = consultations.filter(medecin=form.cleaned_data['medecin'])
        
        if form.cleaned_data.get('patient'):
            consultations = consultations.filter(patient=form.cleaned_data['patient'])
    
    # Pagination
    paginator = Paginator(consultations, 15)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'page_obj': page_obj,
        'form': form,
    }
    
    return render(request, 'admin_interface/consultations/list.html', context)

@login_required
@user_passes_test(is_admin)
def consultation_detail(request, consultation_id):
    consultation = get_object_or_404(Consultation, id=consultation_id)
    prescriptions = Prescription.objects.filter(consultation=consultation)
    messages_list = Message.objects.filter(consultation=consultation).order_by('timestamp')
    
    context = {
        'consultation': consultation,
        'prescriptions': prescriptions,
        'messages_list': messages_list,
    }
    
    return render(request, 'admin_interface/consultations/detail.html', context)

# Gestion des modules de premiers secours
@login_required
@user_passes_test(is_admin)
def first_aid_module_list(request):
    modules = FirstAidModule.objects.all().order_by('order', 'title')
    
    # Filtrage
    category = request.GET.get('category')
    difficulty = request.GET.get('difficulty')
    published = request.GET.get('published')
    search = request.GET.get('search')
    
    if category:
        modules = modules.filter(category=category)
    
    if difficulty:
        modules = modules.filter(difficulty_level=difficulty)
    
    if published:
        is_published = published == 'yes'
        modules = modules.filter(is_published=is_published)
    
    if search:
        modules = modules.filter(
            Q(title__icontains=search) | 
            Q(description__icontains=search)
        )
    
    # Récupérer les catégories existantes pour le filtre
    categories = FirstAidModule.objects.values_list('category', flat=True).distinct()
    
    context = {
        'modules': modules,
        'categories': categories,
        'selected_category': category,
        'selected_difficulty': difficulty,
        'selected_published': published,
        'search': search,
    }
    
    return render(request, 'admin_interface/premiers_secours/liste_de_modules.html', context)

@login_required
@user_passes_test(is_admin)
def first_aid_module_detail(request, module_id):
    module = get_object_or_404(FirstAidModule, id=module_id)
    contents = FirstAidContent.objects.filter(module=module).order_by('order')
    quizzes = Quiz.objects.filter(module=module)
    
    context = {
        'module': module,
        'contents': contents,
        'quizzes': quizzes,
    }
    
    return render(request, 'admin_interface/premiers_secours/détail_du_module.html', context)

@login_required
@user_passes_test(is_admin)
def first_aid_module_create(request):
    if request.method == 'POST':
        form = FirstAidModuleForm(request.POST)
        if form.is_valid():
            module = form.save()
            messages.success(request, "Le module a été créé avec succès.")
            return redirect('admin_interface:first_aid_module_detail', module_id=module.id)
    else:
        form = FirstAidModuleForm()
    
    context = {
        'form': form,
        'title': 'Créer un module de premiers secours',
    }
    
    return render(request, 'admin_interface/premiers_secours/module_form.html', context)

@login_required
@user_passes_test(is_admin)
def first_aid_module_edit(request, module_id):
    module = get_object_or_404(FirstAidModule, id=module_id)
    
    if request.method == 'POST':
        form = FirstAidModuleForm(request.POST, instance=module)
        if form.is_valid():
            module = form.save()
            messages.success(request, "Le module a été mis à jour avec succès.")
            return redirect('admin_interface:first_aid_module_detail', module_id=module.id)
    else:
        form = FirstAidModuleForm(instance=module)
    
    context = {
        'form': form,
        'module': module,
        'title': 'Modifier un module de premiers secours',
    }
    
    return render(request, 'admin_interface/premiers_secours/module_form.html', context)

# Gestion des contenus
@login_required
@user_passes_test(is_admin)
def first_aid_content_create(request, module_id):
    module = get_object_or_404(FirstAidModule, id=module_id)
    
    if request.method == 'POST':
        form = FirstAidContentForm(request.POST, request.FILES)
        if form.is_valid():
            content = form.save(commit=False)
            content.module = module
            
            # Calculer la taille du fichier si présent
            if content.file and hasattr(content.file, 'size'):
                content.file_size = content.file.size // 1024  # Taille en Ko
            
            content.save()
            messages.success(request, "Le contenu a été ajouté avec succès.")
            return redirect('admin_interface:first_aid_module_detail', module_id=module.id)
    else:
        form = FirstAidContentForm()
    
    context = {
        'form': form,
        'module': module,
        'title': 'Ajouter un contenu',
    }
    
    return render(request, 'admin_interface/premiers_secours/formulaire_de_contenu.html', context)

@login_required
@user_passes_test(is_admin)
def first_aid_content_edit(request, content_id):
    content = get_object_or_404(FirstAidContent, id=content_id)
    module = content.module
    
    if request.method == 'POST':
        form = FirstAidContentForm(request.POST, request.FILES, instance=content)
        if form.is_valid():
            content = form.save(commit=False)
            
            # Calculer la taille du fichier si présent et modifié
            if content.file and hasattr(content.file, 'size') and 'file' in request.FILES:
                content.file_size = content.file.size // 1024  # Taille en Ko
            
            content.save()
            messages.success(request, "Le contenu a été mis à jour avec succès.")
            return redirect('admin_interface:first_aid_module_detail', module_id=module.id)
    else:
        form = FirstAidContentForm(instance=content)
    
    context = {
        'form': form,
        'content': content,
        'module': module,
        'title': 'Modifier un contenu',
    }
    
    return render(request, 'admin_interface/premiers_secours/formulaire_de_contenu.html', context)

@login_required
@user_passes_test(is_admin)
def first_aid_content_delete(request, content_id):
    content = get_object_or_404(FirstAidContent, id=content_id)
    module = content.module
    
    if request.method == 'POST':
        content.delete()
        messages.success(request, "Le contenu a été supprimé avec succès.")
        return redirect('admin_interface:first_aid_module_detail', module_id=module.id)
    
    context = {
        'content': content,
        'module': module,
    }
    
    return render(request, 'admin_interface/premiers_secours/content_delete.html', context)

# Gestion des quiz
@login_required
@user_passes_test(is_admin)
def quiz_create(request, module_id):
    module = get_object_or_404(FirstAidModule, id=module_id)
    
    if request.method == 'POST':
        form = QuizForm(request.POST)
        if form.is_valid():
            quiz = form.save(commit=False)
            quiz.module = module
            quiz.save()
            messages.success(request, "Le quiz a été créé avec succès.")
            return redirect('admin_interface:quiz_questions', quiz_id=quiz.id)
    else:
        form = QuizForm()
    
    context = {
        'form': form,
        'module': module,
        'title': 'Créer un quiz',
    }
    
    return render(request, 'admin_interface/premiers_secours/formulaire_de_questionnaire.html', context)

@login_required
@user_passes_test(is_admin)
def quiz_edit(request, quiz_id):
    quiz = get_object_or_404(Quiz, id=quiz_id)
    
    if request.method == 'POST':
        form = QuizForm(request.POST, instance=quiz)
        if form.is_valid():
            quiz = form.save()
            messages.success(request, "Le quiz a été mis à jour avec succès.")
            return redirect('admin_interface:first_aid_module_detail', module_id=quiz.module.id)
    else:
        form = QuizForm(instance=quiz)
    
    context = {
        'form': form,
        'quiz': quiz,
        'title': 'Modifier un quiz',
    }
    
    return render(request, 'admin_interface/premiers_secours/formulaire_de_questionnaire.html', context)

@login_required
@user_passes_test(is_admin)
def quiz_questions(request, quiz_id):
    quiz = get_object_or_404(Quiz, id=quiz_id)
    
    if request.method == 'POST':
        formset = QuizQuestionFormSet(request.POST, instance=quiz)
        if formset.is_valid():
            questions = formset.save(commit=False)
            
            # Gérer les suppressions
            for obj in formset.deleted_objects:
                obj.delete()
            
            # Sauvegarder les questions
            for question in questions:
                question.quiz = quiz
                question.save()
            
            formset.save_m2m()
            
            messages.success(request, "Les questions ont été mises à jour avec succès.")
            
            # Redirection vers la première question pour gérer les options
            if questions:
                return redirect('admin_interface:quiz_question_options', question_id=questions[0].id)
            else:
                question = quiz.questions.first()
                if question:
                    return redirect('admin_interface:quiz_question_options', question_id=question.id)
            
            return redirect('admin_interface:first_aid_module_detail', module_id=quiz.module.id)
    else:
        formset = QuizQuestionFormSet(instance=quiz)
    
    context = {
        'formset': formset,
        'quiz': quiz,
    }
    
    return render(request, 'admin_interface/premiers_secours/formulaire_de_questionnaire.html', context)
@login_required
@user_passes_test(is_admin)
def quiz_question_options(request, question_id):
    question = get_object_or_404(QuizQuestion, id=question_id)
    quiz = question.quiz
    
    if request.method == 'POST':
        formset = QuizOptionFormSet(request.POST, instance=question)
        if formset.is_valid():
            options = formset.save(commit=False)
            
            # Gérer les suppressions
            for obj in formset.deleted_objects:
                obj.delete()
            
            # Sauvegarder les options
            for option in options:
                option.question = question
                option.save()
            
            formset.save_m2m()
            
            messages.success(request, "Les options ont été mises à jour avec succès.")
            
            # Trouver la prochaine question
            next_questions = QuizQuestion.objects.filter(
                quiz=quiz, 
                order__gt=question.order
            ).order_by('order')
            
            if next_questions.exists():
                return redirect('admin_interface:quiz_question_options', question_id=next_questions.first().id)
            
            return redirect('admin_interface:first_aid_module_detail', module_id=quiz.module.id)
    else:
        formset = QuizOptionFormSet(instance=question)
    
    context = {
        'formset': formset,
        'question': question,
        'quiz': quiz,
    }
    
    return render(request, 'admin_interface/premiers_secours/quiz_options.html', context)

# Statistiques et rapports
@login_required
@user_passes_test(is_admin)
def statistics(request):
    # Données de base
    total_users = User.objects.count()
    patients_count = User.objects.filter(role='patient').count()
    medecins_count = User.objects.filter(role='medecin').count()
    
    total_appointments = Appointment.objects.count()
    completed_appointments = Appointment.objects.filter(status='completed').count()
    
    total_consultations = Consultation.objects.count()
    
    # Statistiques mensuelles
    current_month = timezone.now().month
    current_year = timezone.now().year
    
    monthly_registrations = User.objects.filter(
        date_joined__month=current_month,
        date_joined__year=current_year
    ).count()
    
    monthly_appointments = Appointment.objects.filter(
        datetime__month=current_month,
        datetime__year=current_year
    ).count()
    
    monthly_consultations = Consultation.objects.filter(
        start_time__month=current_month,
        start_time__year=current_year
    ).count()
    
    # Distribution des types de consultation
    consultation_types = Consultation.objects.values('type').annotate(count=Count('id'))
    
    # Statistiques d'utilisation des premiers secours
    first_aid_modules = FirstAidModule.objects.all()
    quiz_stats = UserQuizResult.objects.values('quiz__module__title').annotate(
        total=Count('id'),
        avg_score=Avg('score')
    )
    
    context = {
        'total_users': total_users,
        'patients_count': patients_count,
        'medecins_count': medecins_count,
        'total_appointments': total_appointments,
        'completed_appointments': completed_appointments,
        'total_consultations': total_consultations,
        'monthly_registrations': monthly_registrations,
        'monthly_appointments': monthly_appointments,
        'monthly_consultations': monthly_consultations,
        'consultation_types': consultation_types,
        'first_aid_modules': first_aid_modules,
        'quiz_stats': quiz_stats,
    }
    
    return render(request, 'admin_interface/stats.html', context)

@login_required
@user_passes_test(is_admin)
def reports(request):
    # Configuration du rapport
    report_type = request.GET.get('type', 'usage')
    period = request.GET.get('period', 'month')
    
    # Données par défaut
    today = timezone.now().date()
    
    # Déterminer la période
    if period == 'week':
        start_date = today - timezone.timedelta(days=7)
    elif period == 'month':
        start_date = today.replace(day=1)
    elif period == 'quarter':
        quarter_month = ((today.month - 1) // 3) * 3 + 1
        start_date = today.replace(month=quarter_month, day=1)
    elif period == 'year':
        start_date = today.replace(month=1, day=1)
    else:
        start_date = today - timezone.timedelta(days=30)  # Par défaut
    
    # Générer le rapport basé sur le type
    if report_type == 'usage':
        # Rapport d'utilisation
        data = {
            'new_patients': User.objects.filter(
                role='patient', 
                date_joined__gte=start_date
            ).count(),
            'new_medecins': User.objects.filter(
                role='medecin', 
                date_joined__gte=start_date
            ).count(),
            'appointments': Appointment.objects.filter(
                datetime__date__gte=start_date
            ).count(),
            'consultations': Consultation.objects.filter(
                start_time__date__gte=start_date
            ).count(),
            'messages': Message.objects.filter(
                timestamp__date__gte=start_date
            ).count(),
        }
    elif report_type == 'first_aid':
        # Rapport sur l'utilisation des premiers secours
        data = {
            'modules_accessed': UserQuizResult.objects.filter(
                completed_at__date__gte=start_date
            ).values('quiz__module').distinct().count(),
            'quizzes_taken': UserQuizResult.objects.filter(
                completed_at__date__gte=start_date
            ).count(),
            'quizzes_passed': UserQuizResult.objects.filter(
                completed_at__date__gte=start_date,
                passed=True
            ).count(),
            'avg_score': UserQuizResult.objects.filter(
                completed_at__date__gte=start_date
            ).aggregate(avg=Avg('score'))['avg'] or 0,
        }
    elif report_type == 'performance':
        # Rapport de performance
        data = {
            'avg_consultations_per_medecin': Consultation.objects.filter(
                start_time__date__gte=start_date
            ).values('medecin').annotate(count=Count('id')).aggregate(avg=Avg('count'))['avg'] or 0,
            'avg_messages_per_consultation': Message.objects.filter(
                timestamp__date__gte=start_date
            ).values('consultation').annotate(count=Count('id')).aggregate(avg=Avg('count'))['avg'] or 0,
        }
    else:
        data = {}
    
    context = {
        'report_type': report_type,
        'period': period,
        'start_date': start_date,
        'end_date': today,
        'data': data,
    }
    
    return render(request, 'admin_interface/rapports.html', context)