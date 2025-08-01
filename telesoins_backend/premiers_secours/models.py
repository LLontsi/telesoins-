from django.db import models

# Create your models here.
from django.db import models
import uuid
from accounts.models import User

class FirstAidModule(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200, verbose_name="Titre")
    description = models.TextField(verbose_name="Description")
    category = models.CharField(max_length=100, verbose_name="Catégorie")
    difficulty_level = models.IntegerField(
        default=1, 
        choices=[(1, 'Débutant'), (2, 'Intermédiaire'), (3, 'Avancé')],
        verbose_name="Niveau de difficulté"
    )
    order = models.IntegerField(default=0, verbose_name="Ordre d'affichage")
    is_published = models.BooleanField(default=True, verbose_name="Publié")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['order', 'title']
        verbose_name = "Module de premiers secours"
        verbose_name_plural = "Modules de premiers secours"
    
    def __str__(self):
        return self.title

class FirstAidContent(models.Model):
    TYPE_CHOICES = (
        ('video', 'Vidéo'),
        ('image', 'Image'),
        ('audio', 'Audio'),
        ('text', 'Texte'),
        ('checklist', 'Checklist'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    module = models.ForeignKey(FirstAidModule, on_delete=models.CASCADE, related_name='contents')
    title = models.CharField(max_length=200, verbose_name="Titre")
    content_type = models.CharField(max_length=10, choices=TYPE_CHOICES, verbose_name="Type de contenu")
    content = models.TextField(blank=True, verbose_name="Contenu")  # Pour textes et checklists
    file = models.FileField(upload_to='first_aid_content/', null=True, blank=True, verbose_name="Fichier")
    file_size = models.IntegerField(default=0, verbose_name="Taille (Ko)")
    order = models.IntegerField(default=0, verbose_name="Ordre d'affichage")
    
    class Meta:
        ordering = ['module', 'order']
        verbose_name = "Contenu de premiers secours"
        verbose_name_plural = "Contenus de premiers secours"
    
    def __str__(self):
        return f"{self.title} ({self.get_content_type_display()})"

class Quiz(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    module = models.ForeignKey(FirstAidModule, on_delete=models.CASCADE, related_name='quizzes')
    title = models.CharField(max_length=200, verbose_name="Titre")
    description = models.TextField(blank=True, verbose_name="Description")
    passing_score = models.IntegerField(default=70, verbose_name="Score de passage (%)")
    
    class Meta:
        verbose_name = "Quiz"
        verbose_name_plural = "Quiz"
    
    def __str__(self):
        return self.title

class QuizQuestion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='questions')
    question_text = models.TextField(verbose_name="Question")
    order = models.IntegerField(default=0, verbose_name="Ordre")
    
    class Meta:
        ordering = ['order']
        verbose_name = "Question de quiz"
        verbose_name_plural = "Questions de quiz"
    
    def __str__(self):
        return self.question_text

class QuizOption(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    question = models.ForeignKey(QuizQuestion, on_delete=models.CASCADE, related_name='options')
    option_text = models.CharField(max_length=255, verbose_name="Option")
    is_correct = models.BooleanField(default=False, verbose_name="Est correcte")
    
    class Meta:
        verbose_name = "Option de réponse"
        verbose_name_plural = "Options de réponse"
    
    def __str__(self):
        return self.option_text

class UserQuizResult(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='quiz_results')
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='user_results')
    score = models.IntegerField(verbose_name="Score obtenu")
    completed_at = models.DateTimeField(auto_now_add=True)
    passed = models.BooleanField(default=False, verbose_name="Réussi")
    
    class Meta:
        verbose_name = "Résultat de quiz"
        verbose_name_plural = "Résultats de quiz"
        unique_together = ['user', 'quiz']
    
    def __str__(self):
        return f"{self.user.get_full_name()} - {self.quiz.title} - {self.score}%"