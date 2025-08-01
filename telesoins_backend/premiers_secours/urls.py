from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'modules', views.FirstAidModuleViewSet)
router.register(r'contents', views.FirstAidContentViewSet)
router.register(r'quizzes', views.QuizViewSet)
router.register(r'results', views.UserQuizResultViewSet, basename='quiz-results')

app_name = 'premiers_secours'

urlpatterns = [
    path('', include(router.urls)),
]