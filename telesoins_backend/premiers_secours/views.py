from django.shortcuts import render

# Create your views here.
from django.shortcuts import get_object_or_404
from rest_framework import viewsets, permissions, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import FirstAidModule, FirstAidContent, Quiz, QuizQuestion, QuizOption, UserQuizResult
from api.serializers import (
    FirstAidModuleSerializer, FirstAidContentSerializer, 
    QuizSerializer, QuizQuestionSerializer, QuizOptionSerializer,
    UserQuizResultSerializer
)
from api.permissions import IsAuthenticated

class FirstAidModuleViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet pour consulter les modules de premiers secours.
    Seuls les modules publiés sont accessibles.
    """
    queryset = FirstAidModule.objects.filter(is_published=True)
    serializer_class = FirstAidModuleSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'category']
    ordering_fields = ['order', 'title', 'difficulty_level', 'created_at']
    ordering = ['order', 'title']

    @action(detail=True, methods=['get'])
    def contents(self, request, pk=None):
        """
        Récupérer tous les contenus d'un module spécifique.
        """
        module = self.get_object()
        contents = FirstAidContent.objects.filter(module=module).order_by('order')
        serializer = FirstAidContentSerializer(contents, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def quizzes(self, request, pk=None):
        """
        Récupérer tous les quiz d'un module spécifique.
        """
        module = self.get_object()
        quizzes = Quiz.objects.filter(module=module)
        serializer = QuizSerializer(quizzes, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_category(self, request):
        """
        Récupérer les modules regroupés par catégorie.
        """
        categories = FirstAidModule.objects.filter(
            is_published=True
        ).values_list('category', flat=True).distinct()
        
        result = {}
        for category in categories:
            modules = FirstAidModule.objects.filter(
                category=category, 
                is_published=True
            ).order_by('order')
            result[category] = FirstAidModuleSerializer(modules, many=True).data
        
        return Response(result)

    @action(detail=False, methods=['get'])
    def by_difficulty(self, request):
        """
        Récupérer les modules regroupés par niveau de difficulté.
        """
        result = {}
        for level, label in FirstAidModule._meta.get_field('difficulty_level').choices:
            modules = FirstAidModule.objects.filter(
                difficulty_level=level, 
                is_published=True
            ).order_by('order')
            result[label] = FirstAidModuleSerializer(modules, many=True).data
        
        return Response(result)

class FirstAidContentViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet pour consulter les contenus des modules de premiers secours.
    """
    queryset = FirstAidContent.objects.all()
    serializer_class = FirstAidContentSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['order']
    ordering = ['order']

    def get_queryset(self):
        """
        Limiter les contenus à ceux des modules publiés.
        """
        queryset = super().get_queryset()
        return queryset.filter(module__is_published=True)

    @action(detail=False, methods=['get'])
    def by_module(self, request):
        """
        Récupérer les contenus filtrés par module.
        """
        module_id = request.query_params.get('module_id', None)
        if module_id is None:
            return Response(
                {"error": "Le paramètre module_id est requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        module = get_object_or_404(FirstAidModule, pk=module_id, is_published=True)
        contents = FirstAidContent.objects.filter(module=module).order_by('order')
        serializer = self.get_serializer(contents, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        """
        Récupérer les contenus filtrés par type.
        """
        content_type = request.query_params.get('type', None)
        if content_type is None:
            return Response(
                {"error": "Le paramètre type est requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        module_id = request.query_params.get('module_id', None)
        if module_id:
            module = get_object_or_404(FirstAidModule, pk=module_id, is_published=True)
            contents = FirstAidContent.objects.filter(
                module=module, 
                content_type=content_type
            ).order_by('order')
        else:
            contents = FirstAidContent.objects.filter(
                content_type=content_type,
                module__is_published=True
            ).order_by('module__order', 'order')
        
        serializer = self.get_serializer(contents, many=True)
        return Response(serializer.data)

class QuizViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet pour consulter les quiz des modules de premiers secours.
    """
    queryset = Quiz.objects.all()
    serializer_class = QuizSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Limiter les quiz à ceux des modules publiés.
        """
        queryset = super().get_queryset()
        return queryset.filter(module__is_published=True)

    @action(detail=True, methods=['get'])
    def questions(self, request, pk=None):
        """
        Récupérer toutes les questions d'un quiz spécifique.
        """
        quiz = self.get_object()
        questions = QuizQuestion.objects.filter(quiz=quiz).order_by('order')
        serializer = QuizQuestionSerializer(questions, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def submit(self, request, pk=None):
        """
        Soumettre les réponses d'un quiz et obtenir le résultat.
        """
        quiz = self.get_object()
        user = request.user
        answers = request.data.get('answers', {})
        
        if not answers:
            return Response(
                {"error": "Aucune réponse fournie"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Calcul du score
        total_questions = quiz.questions.count()
        if total_questions == 0:
            return Response(
                {"error": "Ce quiz ne contient aucune question"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
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
            user=user,
            quiz=quiz,
            defaults={
                'score': score,
                'passed': passed
            }
        )
        
        # Mettre à jour la progression dans le profil de l'utilisateur
        if hasattr(user, 'patient_profile'):
            # Structure : {'module_id': {'completed': True/False, 'score': 85, 'date': '2023-05-15'}}
            first_aid_progress = user.patient_profile.first_aid_progress or {}
            
            module_id = str(quiz.module.id)
            if module_id not in first_aid_progress:
                first_aid_progress[module_id] = {}
            
            first_aid_progress[module_id]['score'] = score
            first_aid_progress[module_id]['passed'] = passed
            first_aid_progress[module_id]['date'] = result.completed_at.strftime('%Y-%m-%d')
            
            # Vérifier si tous les quiz du module ont été passés
            module_quizzes = Quiz.objects.filter(module=quiz.module)
            completed_quizzes = UserQuizResult.objects.filter(
                user=user, 
                quiz__module=quiz.module
            ).values_list('quiz_id', flat=True)
            
            if set(completed_quizzes) == set(module_quizzes.values_list('id', flat=True)):
                first_aid_progress[module_id]['completed'] = True
            
            user.patient_profile.first_aid_progress = first_aid_progress
            user.patient_profile.save()
        
        serializer = UserQuizResultSerializer(result)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_module(self, request):
        """
        Récupérer les quiz filtrés par module.
        """
        module_id = request.query_params.get('module_id', None)
        if module_id is None:
            return Response(
                {"error": "Le paramètre module_id est requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        module = get_object_or_404(FirstAidModule, pk=module_id, is_published=True)
        quizzes = Quiz.objects.filter(module=module)
        serializer = self.get_serializer(quizzes, many=True)
        return Response(serializer.data)

class UserQuizResultViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet pour consulter les résultats de quiz des utilisateurs.
    Un utilisateur ne peut voir que ses propres résultats.
    """
    serializer_class = UserQuizResultSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserQuizResult.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get'])
    def by_module(self, request):
        """
        Récupérer les résultats de quiz filtrés par module.
        """
        module_id = request.query_params.get('module_id', None)
        if module_id is None:
            return Response(
                {"error": "Le paramètre module_id est requis"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        results = UserQuizResult.objects.filter(
            user=request.user,
            quiz__module__id=module_id
        )
        serializer = self.get_serializer(results, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """
        Récupérer un résumé des résultats de tous les quiz pour l'utilisateur.
        Renvoie la progression pour chaque module.
        """
        user = request.user
        
        if hasattr(user, 'patient_profile'):
            first_aid_progress = user.patient_profile.first_aid_progress or {}
            
            # Enrichir avec des informations supplémentaires sur les modules
            modules = FirstAidModule.objects.filter(is_published=True)
            summary = []
            
            for module in modules:
                module_id = str(module.id)
                module_data = {
                    'module_id': module_id,
                    'module_title': module.title,
                    'module_category': module.category,
                    'module_difficulty': module.get_difficulty_level_display(),
                    'completed': False,
                    'score': 0,
                    'passed': False,
                    'date': None
                }
                
                if module_id in first_aid_progress:
                    module_data.update(first_aid_progress[module_id])
                
                summary.append(module_data)
            
            return Response(summary)
        
        return Response([])