from django.contrib import admin

# Register your models here.
from django.contrib import admin
from .models import FirstAidModule, FirstAidContent, Quiz, QuizQuestion, QuizOption, UserQuizResult

class FirstAidContentInline(admin.TabularInline):
    model = FirstAidContent
    extra = 1
    fields = ('title', 'content_type', 'content', 'file', 'file_size', 'order')

class QuizInline(admin.TabularInline):
    model = Quiz
    extra = 0
    fields = ('title', 'description', 'passing_score')

@admin.register(FirstAidModule)
class FirstAidModuleAdmin(admin.ModelAdmin):
    list_display = ('title', 'category', 'difficulty_level', 'is_published', 'order')
    list_filter = ('category', 'difficulty_level', 'is_published')
    search_fields = ('title', 'description')
    inlines = [FirstAidContentInline, QuizInline]

@admin.register(FirstAidContent)
class FirstAidContentAdmin(admin.ModelAdmin):
    list_display = ('title', 'module', 'content_type', 'order')
    list_filter = ('module', 'content_type')
    search_fields = ('title', 'content')

class QuizOptionInline(admin.TabularInline):
    model = QuizOption
    extra = 4
    fields = ('option_text', 'is_correct')

class QuizQuestionInline(admin.TabularInline):
    model = QuizQuestion
    extra = 1
    fields = ('question_text', 'order')

@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ('title', 'module', 'passing_score')
    list_filter = ('module',)
    search_fields = ('title', 'description')
    inlines = [QuizQuestionInline]

@admin.register(QuizQuestion)
class QuizQuestionAdmin(admin.ModelAdmin):
    list_display = ('question_text', 'quiz', 'order')
    list_filter = ('quiz',)
    search_fields = ('question_text',)
    inlines = [QuizOptionInline]

@admin.register(UserQuizResult)
class UserQuizResultAdmin(admin.ModelAdmin):
    list_display = ('user', 'quiz', 'score', 'passed', 'completed_at')
    list_filter = ('passed', 'quiz', 'completed_at')
    search_fields = ('user__email', 'user__first_name', 'quiz__title')
    date_hierarchy = 'completed_at'