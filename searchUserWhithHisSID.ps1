# V0.0.1

######################################################################################################
#                                                                                                    #
#                             Get User AD information from its SID                                   #
#                                                                                                    #
######################################################################################################


function Validate-SID {
    param (
        [string]$SID
    )
    try {
        $sidObject = New-Object System.Security.Principal.SecurityIdentifier($SID)
        return $true
    } catch {
        Write-Host "Le SID '$SID' n'est pas valide. Un SID valide ressemble à S-1-5-21-XXXXXXX-XXXXXXX-XXXXXXX-XXXX."
        return $false
    }
}

# Demander le SID
do {
    $SID = Read-Host "Entrez le SID de l'utilisateur"
} while (-not (Validate-SID -SID $SID))

# Importer le module Active Directory
Import-Module ActiveDirectory

# Demander les informations d'identification et traiter les erreurs d'authentification
$authenticated = $false
while (-not $authenticated) {
    # Demander le login et le mot de passe de l'administrateur
    $adminUsername = Read-Host "Entrez le login administrateur"
    $adminPassword = Read-Host "Entrez le mot de passe administrateur" -AsSecureString

    # Convertir le mot de passe en format sécurisé pour ne pas qu'il circule en clair
    $cred = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)

    try {
        # Essayer d'interroger Active Directory avec les informations d'identification fournies
        $user = Get-ADUser -Filter { ObjectSID -eq $SID } -Credential $cred -Properties *
        $authenticated = $true  # Authentification réussie
    } catch {
        Write-Host "Erreur d'authentification. Veuillez vérifier vos informations d'identification et réessayer."
    }
}

if ($user) {
    # Afficher les informations de l'utilisateur
    Write-Host "Nom d'utilisateur: $($user.SamAccountName)"
    Write-Host "Propriétés du compte utilisateur: "
    $user | Format-List

    # Générer un rapport TXT
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $reportContent = @(
        "Date et heure de la demande : $timestamp"
        "Compte demandeur : $adminUsername"
        "SID demandé : $SID"
        "Login recherché : $($user.SamAccountName)"
        ""
        "Propriétés du compte utilisateur :"
        ""
        ($user | Out-String)
    )
    $reportFilename = "Rapport_Info_AD_User_$($user.SamAccountName).txt"
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath $reportFilename
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "Le rapport a été généré avec succès à l'emplacement $reportPath"
} else {
    Write-Host "Aucun utilisateur trouvé avec le SID '$SID'."
}

# Empêcher la fenêtre PowerShell de se fermer immédiatement
Write-Host "Appuyez sur une touche pour terminer..."
[System.Console]::ReadKey($true)
