# PowerShell Scripts - CloudFox-IT

Scripts PowerShell pour l'administration système Windows (AD, WSUS, WinRM, Endpoints).

---

##  Organisation

###  AD - Active Directory
| Script | Description |
|--------|-------------|
| Export-GroupComputers.ps1 | Exporte les postes d'un groupe AD vers un CSV |
| ExportAD.ps1 | Export général de l'AD |
| wsuscomparaisonad.ps1 | Comparaison entre AD et WSUS |

###  WSUS - Windows Update
| Script | Description |
|--------|-------------|
| scriptverifwsus.ps1 | Vérifie l'état WSUS des postes |
| Resultats_WSUS_Server.ps1 | Résultats des mises à jour serveur |
| Remonterpcserveurinwsus.ps1 | Force la remontée dans WSUS |

###  WinRM
| Script | Description |
|--------|-------------|
| verifwinrm.ps1 | Vérifie si WinRM est actif |
| winrm_quickconfig.ps1 | Configure WinRM rapidement |

### Endpoints - Gestion des postes
| Script | Description |
|--------|-------------|
| etatpc2.ps1 | Vérifie l'état des PCs |
| pckodepuis.ps1 | PCs en erreur depuis X jours |

---

## Auteur
**Sylvain Mirlaud** - Ing sysinfra