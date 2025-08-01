from rest_framework import permissions
from rest_framework.permissions import IsAuthenticated

class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Permission personnalisée pour permettre uniquement aux propriétaires d'un objet de le modifier.
    """
    def has_object_permission(self, request, view, obj):
        # Les permissions en lecture sont autorisées pour toute requête
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Les permissions d'écriture ne sont accordées qu'au propriétaire
        if hasattr(obj, 'user'):
            return obj.user == request.user
        elif hasattr(obj, 'patient'):
            return obj.patient == request.user
        elif hasattr(obj, 'sender'):
            return obj.sender == request.user
        elif hasattr(obj, 'owner'):
            return obj.owner == request.user
        
        # Par défaut, refuser l'accès
        return False

class IsMedecin(permissions.BasePermission):
    """
    Permission pour accès uniquement aux médecins.
    """
    def has_permission(self, request, view):
        return request.user and request.user.role == 'medecin'

class IsPatient(permissions.BasePermission):
    """
    Permission pour accès uniquement aux patients.
    """
    def has_permission(self, request, view):
        return request.user and request.user.role == 'patient'

class IsAdmin(permissions.BasePermission):
    """
    Permission pour accès uniquement aux administrateurs.
    """
    def has_permission(self, request, view):
        return request.user and (request.user.role == 'admin' or request.user.is_staff)