const prisma = require('../config/database')
const bcrypt = require('bcryptjs')
const { validerNom, validerMotDePasse, validerTelephone } = require('../utils/validation')

// Voir son profil
const getMonProfil = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { idUser: req.user.idUser },
      select: {
        idUser: true,
        nomUser: true,
        prenomUser: true,
        emailUser: true,
        roleUser: true,
        photoProfilUser: true,
        bioUser: true,
        numeroTelUser: true,
        dateInscriptionUser: true,
        ville: { select: { idVille: true, nomVille: true } },
        operateur: { select: { idOperateur: true, nomOperateur: true } },
        enseignant: {
          select: {
            idEnseignant: true,
            specialiteEnseignant: true,
            titreProfessionnelEnseignant: true,
            reseauxSociaux: true
          }
        },
        apprenant: {
          select: {
            idApprenant: true,
            niveauApprenant: true,
            etablissement: { select: { idEtablissement: true, nomEtablissement: true } }
          }
        }
      }
    })

    res.status(200).json(user)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Modifier infos de base
const modifierProfil = async (req, res) => {
  try {
    const { nomUser, prenomUser, bioUser, idVille, idOperateur, numeroTelUser } = req.body

    if (nomUser) {
      const validNom = validerNom(nomUser)
      if (!validNom.valide) return res.status(400).json({ message: validNom.message })
    }

    if (prenomUser) {
      const validPrenom = validerNom(prenomUser)
      if (!validPrenom.valide) return res.status(400).json({ message: validPrenom.message })
    }

    // Vérifier numéro tel si modifié
    if (numeroTelUser && idOperateur) {
      const operateur = await prisma.operateur.findUnique({ where: { idOperateur } })
      if (!operateur) return res.status(400).json({ message: 'Opérateur invalide' })

      const operateursDuPays = await prisma.operateur.findMany({ where: { idPays: operateur.idPays } })
      const validTel = validerTelephone(numeroTelUser, operateursDuPays)
      if (!validTel.valide) return res.status(400).json({ message: validTel.message })

      // Vérifier que le numéro n'est pas déjà utilisé par un autre user
      const telExiste = await prisma.user.findFirst({
        where: { numeroTelUser, idUser: { not: req.user.idUser } }
      })
      if (telExiste) return res.status(400).json({ message: 'Ce numéro est déjà utilisé' })
    }

    const user = await prisma.user.update({
      where: { idUser: req.user.idUser },
      data: {
        nomUser: nomUser || req.user.nomUser,
        prenomUser: prenomUser || req.user.prenomUser,
        bioUser: bioUser !== undefined ? bioUser : req.user.bioUser,
        idVille: idVille || req.user.idVille,
        idOperateur: idOperateur || req.user.idOperateur,
        numeroTelUser: numeroTelUser || req.user.numeroTelUser,
      },
      select: {
        idUser: true, nomUser: true, prenomUser: true,
        emailUser: true, roleUser: true, bioUser: true,
        numeroTelUser: true
      }
    })

    res.status(200).json({ message: 'Profil modifié avec succès', user })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Upload photo de profil
const uploadPhoto = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'Aucune image fournie' })

    const photoUrl = `/uploads/images/${req.file.filename}`

    await prisma.user.update({
      where: { idUser: req.user.idUser },
      data: { photoProfilUser: photoUrl }
    })

    res.status(200).json({ message: 'Photo de profil mise à jour', photoUrl })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Modifier mot de passe
const modifierMotDePasse = async (req, res) => {
  try {
    const { ancienPassword, nouveauPassword } = req.body

    if (!ancienPassword || !nouveauPassword) {
      return res.status(400).json({ message: 'Ancien et nouveau mot de passe obligatoires' })
    }

    const user = await prisma.user.findUnique({ where: { idUser: req.user.idUser } })

    const ancienValide = await bcrypt.compare(ancienPassword, user.passwordUser)
    if (!ancienValide) return res.status(400).json({ message: 'Ancien mot de passe incorrect' })

    const validPassword = validerMotDePasse(nouveauPassword)
    if (!validPassword.valide) return res.status(400).json({ message: validPassword.message })

    const hashedPassword = await bcrypt.hash(nouveauPassword, 12)

    await prisma.user.update({
      where: { idUser: req.user.idUser },
      data: { passwordUser: hashedPassword }
    })

    res.status(200).json({ message: 'Mot de passe modifié avec succès' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Modifier profil enseignant
const modifierProfilEnseignant = async (req, res) => {
  try {
    const { specialiteEnseignant, titreProfessionnelEnseignant } = req.body

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const enseignantModifie = await prisma.enseignant.update({
      where: { idEnseignant: enseignant.idEnseignant },
      data: {
        specialiteEnseignant: specialiteEnseignant || enseignant.specialiteEnseignant,
        titreProfessionnelEnseignant: titreProfessionnelEnseignant || enseignant.titreProfessionnelEnseignant
      }
    })

    res.status(200).json({ message: 'Profil enseignant modifié', enseignant: enseignantModifie })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Ajouter réseau social
const ajouterReseauSocial = async (req, res) => {
  try {
    const { plateformeRS, lienRS } = req.body

    if (!plateformeRS || !lienRS) {
      return res.status(400).json({ message: 'Plateforme et lien obligatoires' })
    }

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const rs = await prisma.reseauxSociaux.create({
      data: { idEnseignant: enseignant.idEnseignant, plateformeRS, lienRS }
    })

    res.status(201).json({ message: 'Réseau social ajouté', reseauSocial: rs })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Modifier réseau social
const modifierReseauSocial = async (req, res) => {
  try {
    const { idReseauxSociaux } = req.params
    const { plateformeRS, lienRS } = req.body

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const rs = await prisma.reseauxSociaux.findUnique({ where: { idReseauxSociaux } })
    if (!rs) return res.status(404).json({ message: 'Réseau social introuvable' })

    if (rs.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    const rsModifie = await prisma.reseauxSociaux.update({
      where: { idReseauxSociaux },
      data: {
        plateformeRS: plateformeRS || rs.plateformeRS,
        lienRS: lienRS || rs.lienRS
      }
    })

    res.status(200).json({ message: 'Réseau social modifié', reseauSocial: rsModifie })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Supprimer réseau social
const supprimerReseauSocial = async (req, res) => {
  try {
    const { idReseauxSociaux } = req.params

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const rs = await prisma.reseauxSociaux.findUnique({ where: { idReseauxSociaux } })
    if (!rs) return res.status(404).json({ message: 'Réseau social introuvable' })

    if (rs.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    await prisma.reseauxSociaux.delete({ where: { idReseauxSociaux } })

    res.status(200).json({ message: 'Réseau social supprimé' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Modifier profil apprenant
const modifierProfilApprenant = async (req, res) => {
  try {
    const { niveauApprenant, idEtablissement } = req.body

    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const apprenantModifie = await prisma.apprenant.update({
      where: { idApprenant: apprenant.idApprenant },
      data: {
        niveauApprenant: niveauApprenant || apprenant.niveauApprenant,
        idEtablissement: idEtablissement !== undefined ? idEtablissement : apprenant.idEtablissement
      }
    })

    res.status(200).json({ message: 'Profil apprenant modifié', apprenant: apprenantModifie })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = {
  getMonProfil,
  modifierProfil,
  uploadPhoto,
  modifierMotDePasse,
  modifierProfilEnseignant,
  ajouterReseauSocial,
  modifierReseauSocial,
  supprimerReseauSocial,
  modifierProfilApprenant
}