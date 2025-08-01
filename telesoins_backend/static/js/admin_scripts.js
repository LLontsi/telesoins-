// JavaScript pour l'interface administrateur

// Fonction pour initialiser les tableaux dynamiques
function initDataTables() {
    if ($.fn.DataTable) {
        $('.datatable').DataTable({
            language: {
                url: '//cdn.datatables.net/plug-ins/1.10.24/i18n/French.json'
            },
            responsive: true,
            pageLength: 10
        });
    }
}

// Fonction pour initialiser les graphiques avec Chart.js
function initCharts() {
    // Uniquement exécuter si nous avons des éléments de graphique
    if ($('.chart-container').length > 0) {
        // Configuration des couleurs pour les graphiques
        const chartColors = {
            red: '#e63946',
            blue: '#457b9d',
            dark: '#1d3557',
            light: '#f1faee',
            green: '#2a9d8f',
            yellow: '#e9c46a',
            orange: '#e76f51'
        };
        
        // Si nous avons un graphique spécifique, l'initialiser
        if ($('#usageChart').length > 0) {
            const ctx = document.getElementById('usageChart').getContext('2d');
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: usageLabels || [],
                    datasets: [{
                        label: 'Consultations',
                        data: usageData || [],
                        backgroundColor: chartColors.red,
                        borderColor: chartColors.red,
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    }
                }
            });
        }
        
        // Autres initialisations de graphiques selon les besoins
    }
}

// Gestion des formulaires dynamiques (comme les formsets)
function initDynamicForms() {
    $('.add-form-row').click(function(e) {
        e.preventDefault();
        const formsetName = $(this).data('formset');
        const totalForms = $(`#id_${formsetName}-TOTAL_FORMS`).val();
        const formsetContainer = $(`#${formsetName}-container`);
        
        // Cloner le premier formulaire et mettre à jour les indices
        const newForm = formsetContainer.find('.form-row:first').clone(true);
        newForm.find(':input').each(function() {
            const name = $(this).attr('name');
            if (name) {
                const newName = name.replace('-0-', `-${totalForms}-`);
                $(this).attr('name', newName);
                $(this).attr('id', newName);
                $(this).val('');
            }
        });
        
        // Mettre à jour les étiquettes et indices
        newForm.find('label').each(function() {
            const forAttr = $(this).attr('for');
            if (forAttr) {
                const newForAttr = forAttr.replace('-0-', `-${totalForms}-`);
                $(this).attr('for', newForAttr);
            }
        });
        
        // Ajouter le nouveau formulaire et mettre à jour le compteur
        formsetContainer.append(newForm);
        $(`#id_${formsetName}-TOTAL_FORMS`).val(parseInt(totalForms) + 1);
    });
    
    $('.delete-form-row').click(function(e) {
        e.preventDefault();
        const formRow = $(this).closest('.form-row');
        formRow.find('[id$=DELETE]').prop('checked', true);
        formRow.hide();
    });
}

// Fonction pour la navigation à onglets réactive
function initTabs() {
    $('.nav-tabs a').on('click', function (e) {
        e.preventDefault();
        $(this).tab('show');
    });
}

// Initialisation au chargement de la page
$(document).ready(function () {
    initDataTables();
    initCharts();
    initDynamicForms();
    initTabs();
    
    // Gérer les messages flash avec disparition automatique
    setTimeout(function() {
        $('.alert-dismissible').alert('close');
    }, 5000);
    
    // Activer les tooltips Bootstrap
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
});