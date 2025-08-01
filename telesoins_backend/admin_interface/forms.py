from django import forms
from accounts.models import User, PatientProfile, MedecinProfile
from consultations.models import Appointment, Consultation
from premiers_secours.models import FirstAidModule, FirstAidContent, Quiz, QuizQuestion, QuizOption

class LoginForm(forms.Form):
    email = forms.EmailField(label="Email", widget=forms.EmailInput(attrs={'class': 'form-control'}))
    password = forms.CharField(label="Mot de passe", widget=forms.PasswordInput(attrs={'class': 'form-control'}))

class UserForm(forms.ModelForm):
    password1 = forms.CharField(label="Mot de passe", widget=forms.PasswordInput(attrs={'class': 'form-control'}), required=False)
    password2 = forms.CharField(label="Confirmer le mot de passe", widget=forms.PasswordInput(attrs={'class': 'form-control'}), required=False)
    
    class Meta:
        model = User
        fields = ['email', 'first_name', 'last_name', 'role', 'phone_number', 'profile_photo', 'is_active', 'is_verified']
        widgets = {
            'email': forms.EmailInput(attrs={'class': 'form-control'}),
            'first_name': forms.TextInput(attrs={'class': 'form-control'}),
            'last_name': forms.TextInput(attrs={'class': 'form-control'}),
            'role': forms.Select(attrs={'class': 'form-select'}),
            'phone_number': forms.TextInput(attrs={'class': 'form-control'}),
            'profile_photo': forms.FileInput(attrs={'class': 'form-control'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'is_verified': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }
    
    def __init__(self, *args, **kwargs):
        super(UserForm, self).__init__(*args, **kwargs)
        # Les champs de mot de passe sont facultatifs pour la mise à jour
        if self.instance.pk:
            self.fields['password1'].required = False
            self.fields['password2'].required = False
        else:
            self.fields['password1'].required = True
            self.fields['password2'].required = True
    
    def clean(self):
        cleaned_data = super().clean()
        password1 = cleaned_data.get("password1")
        password2 = cleaned_data.get("password2")
        
        if password1 and password1 != password2:
            raise forms.ValidationError("Les mots de passe ne correspondent pas.")
        
        return cleaned_data
    
    def save(self, commit=True):
        user = super().save(commit=False)
        if self.cleaned_data.get('password1'):
            user.set_password(self.cleaned_data['password1'])
        
        if commit:
            user.save()
        return user

class PatientProfileForm(forms.ModelForm):
    class Meta:
        model = PatientProfile
        fields = ['date_of_birth', 'medical_history', 'allergies', 'blood_type']
        widgets = {
            'date_of_birth': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'medical_history': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'allergies': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'blood_type': forms.TextInput(attrs={'class': 'form-control'}),
        }

class MedecinProfileForm(forms.ModelForm):
    class Meta:
        model = MedecinProfile
        fields = ['speciality', 'licence_number', 'years_of_experience']
        widgets = {
            'speciality': forms.TextInput(attrs={'class': 'form-control'}),
            'licence_number': forms.TextInput(attrs={'class': 'form-control'}),
            'years_of_experience': forms.NumberInput(attrs={'class': 'form-control'}),
        }
class AppointmentForm(forms.ModelForm):
    class Meta:
        model = Appointment
        fields = ['patient', 'medecin', 'datetime', 'status', 'reason', 'notes', 'is_urgent']
        widgets = {
            'patient': forms.Select(attrs={'class': 'form-select'}),
            'medecin': forms.Select(attrs={'class': 'form-select'}),
            'datetime': forms.DateTimeInput(attrs={'class': 'form-control', 'type': 'datetime-local'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
            'reason': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'notes': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'is_urgent': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }
    
    def __init__(self, *args, **kwargs):
        super(AppointmentForm, self).__init__(*args, **kwargs)
        # Filtrer les patients et médecins
        self.fields['patient'].queryset = User.objects.filter(role='patient')
        self.fields['medecin'].queryset = User.objects.filter(role='medecin')

class ConsultationFilterForm(forms.Form):
    start_date = forms.DateField(label="Date de début", required=False, widget=forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}))
    end_date = forms.DateField(label="Date de fin", required=False, widget=forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}))
    type = forms.ChoiceField(label="Type", choices=[('', '---')] + list(Consultation.TYPE_CHOICES), required=False, widget=forms.Select(attrs={'class': 'form-select'}))
    medecin = forms.ModelChoiceField(label="Médecin", queryset=User.objects.filter(role='medecin'), required=False, widget=forms.Select(attrs={'class': 'form-select'}))
    patient = forms.ModelChoiceField(label="Patient", queryset=User.objects.filter(role='patient'), required=False, widget=forms.Select(attrs={'class': 'form-select'}))

class FirstAidModuleForm(forms.ModelForm):
    class Meta:
        model = FirstAidModule
        fields = ['title', 'description', 'category', 'difficulty_level', 'order', 'is_published']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'category': forms.TextInput(attrs={'class': 'form-control'}),
            'difficulty_level': forms.Select(attrs={'class': 'form-select'}),
            'order': forms.NumberInput(attrs={'class': 'form-control'}),
            'is_published': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class FirstAidContentForm(forms.ModelForm):
    class Meta:
        model = FirstAidContent
        fields = ['title', 'content_type', 'content', 'file', 'order']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'content_type': forms.Select(attrs={'class': 'form-select'}),
            'content': forms.Textarea(attrs={'class': 'form-control', 'rows': 5}),
            'file': forms.FileInput(attrs={'class': 'form-control'}),
            'order': forms.NumberInput(attrs={'class': 'form-control'}),
        }

class QuizForm(forms.ModelForm):
    class Meta:
        model = Quiz
        fields = ['title', 'description', 'passing_score']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'passing_score': forms.NumberInput(attrs={'class': 'form-control'}),
        }

class QuizQuestionForm(forms.ModelForm):
    class Meta:
        model = QuizQuestion
        fields = ['question_text', 'order']
        widgets = {
            'question_text': forms.Textarea(attrs={'class': 'form-control', 'rows': 2}),
            'order': forms.NumberInput(attrs={'class': 'form-control'}),
        }

class QuizOptionForm(forms.ModelForm):
    class Meta:
        model = QuizOption
        fields = ['option_text', 'is_correct']
        widgets = {
            'option_text': forms.TextInput(attrs={'class': 'form-control'}),
            'is_correct': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

QuizOptionFormSet = forms.inlineformset_factory(
    QuizQuestion, 
    QuizOption, 
    form=QuizOptionForm, 
    extra=4, 
    can_delete=True,
    min_num=2,
)

QuizQuestionFormSet = forms.inlineformset_factory(
    Quiz, 
    QuizQuestion, 
    form=QuizQuestionForm, 
    extra=1, 
    can_delete=True,
)