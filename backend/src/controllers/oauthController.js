const jwt = require('jsonwebtoken')
const prisma = require('../config/database')

const genererToken = (user) => {
  return jwt.sign(
    { idUser: user.idUser, roleUser: user.roleUser },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  )
}

const googleCallback = async (req, res) => {
  try {
    const { user, isNewUser } = req.user
    const token = genererToken(user)

    const params = new URLSearchParams({
      token,
      idUser: user.idUser,
      nomUser: user.nomUser,
      prenomUser: user.prenomUser,
      emailUser: user.emailUser,
      roleUser: user.roleUser,
      photoProfilUser: user.photoProfilUser || '',
      isNewUser: isNewUser.toString()
    })

    res.redirect(`${process.env.FRONTEND_URL}/oauth?${params.toString()}`)
  } catch (error) {
    res.redirect(`${process.env.FRONTEND_URL}/oauth?error=true`)
  }
}

const githubCallback = async (req, res) => {
  try {
    const { user, isNewUser } = req.user
    const token = genererToken(user)

    const params = new URLSearchParams({
      token,
      idUser: user.idUser,
      nomUser: user.nomUser,
      prenomUser: user.prenomUser,
      emailUser: user.emailUser,
      roleUser: user.roleUser,
      photoProfilUser: user.photoProfilUser || '',
      isNewUser: isNewUser.toString()
    })

    res.redirect(`${process.env.FRONTEND_URL}/oauth?${params.toString()}`)
  } catch (error) {
    res.redirect(`${process.env.FRONTEND_URL}/oauth?error=true`)
  }
}

const completerProfil = async (req, res) => {
  try {
    const {
      roleUser, idVille, idOperateur, numeroTelUser,
      bioUser, niveauApprenant, idEtablissement,
      specialiteEnseignant, titreProfessionnelEnseignant
    } = req.body

    if (!roleUser || !['ENSEIGNANT', 'APPRENANT'].includes(roleUser)) {
      return res.status(400).json({ message: 'Rôle invalide' })
    }

    const result = await prisma.$transaction(async (tx) => {
      // Mettre à jour User
      const user = await tx.user.update({
        where: { idUser: req.user.idUser },
        data: {
          roleUser,
          bioUser: bioUser || null,
          idVille: idVille || null,
          idOperateur: idOperateur || null,
          numeroTelUser: numeroTelUser || null,
        }
      })

      // Supprimer ancien rôle si existe
      await tx.apprenant.deleteMany({ where: { idUser: user.idUser } })
      await tx.enseignant.deleteMany({ where: { idUser: user.idUser } })

      // Créer nouveau rôle
      if (roleUser === 'ENSEIGNANT') {
        await tx.enseignant.create({
          data: {
            idUser: user.idUser,
            specialiteEnseignant: specialiteEnseignant || null,
            titreProfessionnelEnseignant: titreProfessionnelEnseignant || null,
          }
        })
      } else {
        await tx.apprenant.create({
          data: {
            idUser: user.idUser,
            niveauApprenant: niveauApprenant || null,
            idEtablissement: idEtablissement || null,
          }
        })
      }

      return user
    })

    // Nouveau token avec roleUser mis à jour
    const token = jwt.sign(
      { idUser: result.idUser, roleUser: result.roleUser },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    )

    res.status(200).json({
      message: 'Profil complété avec succès',
      token,
      user: {
        idUser: result.idUser,
        nomUser: result.nomUser,
        prenomUser: result.prenomUser,
        emailUser: result.emailUser,
        roleUser: result.roleUser,
      }
    })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = { googleCallback, githubCallback, completerProfil }