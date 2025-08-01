from rest_framework import serializers
from accounts.models import User, PatientProfile, MedecinProfile
from consultations.models import Appointment, Consultation, Prescription, Message
from premiers_secours.models import FirstAidModule, FirstAidContent, Quiz, QuizQuestion, QuizOption, UserQuizResult
from django.contrib.auth.password_validation import validate_password

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'role', 'phone_number', 
                  'profile_photo', 'is_verified', 'created_at']
        read_only_fields = ['is_verified', 'created_at']

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ['email', 'first_name', 'last_name', 'password', 'password2', 
                  'role', 'phone_number', 'profile_photo']
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Les mots de passe ne correspondent pas."})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user

class PatientProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = PatientProfile
        fields = ['user', 'date_of_birth', 'emergency_contacts', 'medical_history', 
                  'allergies', 'blood_type', 'first_aid_progress']

class MedecinProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = MedecinProfile
        fields = ['user', 'speciality', 'licence_number', 'years_of_experience', 
                  'available_hours', 'triage_protocols']

class AppointmentSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    medecin_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Appointment
        fields = ['id', 'patient', 'medecin', 'patient_name', 'medecin_name', 
                  'datetime', 'status', 'reason', 'notes', 'is_urgent', 
                  'created_at', 'updated_at']
    
    def get_patient_name(self, obj):
        return f"{obj.patient.first_name} {obj.patient.last_name}"
    
    def get_medecin_name(self, obj):
        return f"{obj.medecin.first_name} {obj.medecin.last_name}"

class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = ['id', 'consultation', 'sender', 'sender_name', 'content', 
                  'attachment', 'timestamp', 'is_read']
    
    def get_sender_name(self, obj):
        return f"{obj.sender.first_name} {obj.sender.last_name}"

class PrescriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Prescription
        fields = ['id', 'consultation', 'details', 'created_at', 'valid_until']

class ConsultationSerializer(serializers.ModelSerializer):
    prescriptions = PrescriptionSerializer(many=True, read_only=True)
    messages = MessageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Consultation
        fields = ['id', 'appointment', 'patient', 'medecin', 'type', 
                  'start_time', 'end_time', 'summary', 'diagnosis', 
                  'prescriptions', 'messages']

class QuizOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizOption
        fields = ['id', 'option_text', 'is_correct']

class QuizQuestionSerializer(serializers.ModelSerializer):
    options = QuizOptionSerializer(many=True, read_only=True)
    
    class Meta:
        model = QuizQuestion
        fields = ['id', 'question_text', 'order', 'options']

class QuizSerializer(serializers.ModelSerializer):
    questions = QuizQuestionSerializer(many=True, read_only=True)
    
    class Meta:
        model = Quiz
        fields = ['id', 'module', 'title', 'description', 'passing_score', 'questions']

class FirstAidContentSerializer(serializers.ModelSerializer):
    class Meta:
        model = FirstAidContent
        fields = ['id', 'module', 'title', 'content_type', 'content', 
                  'file', 'file_size', 'order']

class FirstAidModuleSerializer(serializers.ModelSerializer):
    contents = FirstAidContentSerializer(many=True, read_only=True)
    quizzes = QuizSerializer(many=True, read_only=True)
    
    class Meta:
        model = FirstAidModule
        fields = ['id', 'title', 'description', 'category', 'difficulty_level', 
                  'order', 'is_published', 'created_at', 'updated_at', 
                  'contents', 'quizzes']

class UserQuizResultSerializer(serializers.ModelSerializer):
    quiz_title = serializers.SerializerMethodField()
    
    class Meta:
        model = UserQuizResult
        fields = ['id', 'user', 'quiz', 'quiz_title', 'score', 'completed_at', 'passed']
    
    def get_quiz_title(self, obj):
        return obj.quiz.title