const prisma = require('../config/database')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')
const transporter = require('../config/mailer')
const { validerNom, validerFormatEmail, validerMotDePasse, validerTelephone } = require('../utils/validation')

// Générer un code 6 chiffres
const genererCode = () => Math.floor(100000 + Math.random() * 900000).toString()

// ETAPE 1 - Valider nom et prénom
const validerNomPrenom = (req, res) => {
  const { nomUser, prenomUser } = req.body
  console.log('REÇU:', JSON.stringify({ nomUser, prenomUser }))
  const validNom = validerNom(nomUser)
  if (!validNom.valide) return res.status(400).json({ valide: false, champ: 'nomUser', message: validNom.message })

  const validPrenom = validerNom(prenomUser)
  if (!validPrenom.valide) return res.status(400).json({ valide: false, champ: 'prenomUser', message: validPrenom.message })

  res.status(200).json({ valide: true, message: 'Nom et prénom valides' })
}

// ETAPE 2 - Vérifier email dynamiquement
const verifierEmailInscription = async (req, res) => {
  try {
    const { emailUser } = req.body

    const formatValide = validerFormatEmail(emailUser)
    if (!formatValide.valide) {
      return res.status(400).json({ valide: false, message: formatValide.message })
    }

    const userExiste = await prisma.user.findUnique({ where: { emailUser } })
    if (userExiste) {
      return res.status(400).json({ valide: false, message: 'Cet email est déjà utilisé' })
    }

    res.status(200).json({ valide: true, message: 'Email disponible' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// ETAPE 3 - Envoyer code de vérification
const envoyerCodeVerification = async (req, res) => {
  try {
    const { emailUser } = req.body

    if (!emailUser) return res.status(400).json({ message: 'Email obligatoire' })

    // Invalider les anciens codes
    await prisma.codeVerification.updateMany({
      where: { emailUser, estUtilise: false },
      data: { estUtilise: true }
    })

    const code = genererCode()
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000) // 10 minutes

    await prisma.codeVerification.create({
      data: { codeVerification: code, emailUser, expiresAt }
    })

    await transporter.sendMail({
      from: `"LMS Platform" <${process.env.GMAIL_USER}>`,
      to: emailUser,
      subject: 'Code de vérification',
      html: `
        <h2>Vérification de votre email</h2>
        <p>Votre code de vérification est :</p>
        <h1 style="letter-spacing: 8px; color: #4F46E5;">${code}</h1>
        <p>Ce code expire dans <strong>10 minutes</strong>.</p>
      `
    })

    res.status(200).json({ message: 'Code envoyé sur votre email' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const verifierCode = async (req, res) => {
  try {
    const { emailUser, code } = req.body

    // ── ÉTAPE 1 : Champs présents ──────────────────────────────
    console.log(`[verifierCode] Requête reçue → email: "${emailUser}", code: "${code}"`)

    if (!emailUser || !code) {
      console.warn(`[verifierCode] ✗ Champ manquant → emailUser: ${!!emailUser}, code: ${!!code}`)
      return res.status(400).json({ valide: false, message: 'Email et code obligatoires' })
    }

    // ── ÉTAPE 2 : Normalisation ────────────────────────────────
    const codeNormalise = String(code).trim()
    console.log(`[verifierCode] Code normalisé: "${codeNormalise}" (longueur: ${codeNormalise.length})`)

    if (codeNormalise.length !== 6 || !/^\d{6}$/.test(codeNormalise)) {
      console.warn(`[verifierCode] ✗ Format invalide: "${codeNormalise}"`)
      return res.status(400).json({ valide: false, message: 'Le code doit contenir 6 chiffres' })
    }

    // ── ÉTAPE 3 : Code existe en base ? ───────────────────────
    const codeExiste = await prisma.codeVerification.findFirst({
      where: { emailUser, codeVerification: codeNormalise },
      orderBy: { dateCreation: 'desc' }
    })

    if (!codeExiste) {
      console.warn(`[verifierCode] ✗ Code "${codeNormalise}" introuvable en base pour "${emailUser}"`)

      // Log tous les codes de cet email pour comparer
      const tousLesCodes = await prisma.codeVerification.findMany({
        where: { emailUser },
        orderBy: { dateCreation: 'desc' },
        take: 3
      })
      console.log(`[verifierCode] Codes existants pour "${emailUser}":`,
        tousLesCodes.map(c => ({
          code: c.codeVerification,
          estUtilise: c.estUtilise,
          expiresAt: c.expiresAt,
          expireDepuis: c.expiresAt < new Date()
            ? `expiré depuis ${Math.round((Date.now() - c.expiresAt) / 1000)}s`
            : `valide encore ${Math.round((c.expiresAt - Date.now()) / 1000)}s`
        }))
      )

      return res.status(400).json({ valide: false, message: 'Code incorrect' })
    }

    console.log(`[verifierCode] Code trouvé → estUtilise: ${codeExiste.estUtilise}, expiresAt: ${codeExiste.expiresAt}`)

    // ── ÉTAPE 4 : Déjà utilisé ? ───────────────────────────────
    if (codeExiste.estUtilise) {
      console.warn(`[verifierCode] ✗ Code déjà utilisé pour "${emailUser}"`)
      return res.status(400).json({ valide: false, message: 'Ce code a déjà été utilisé. Demandez un nouveau code.' })
    }

    // ── ÉTAPE 5 : Expiré ? ─────────────────────────────────────
    if (codeExiste.expiresAt < new Date()) {
      const secondesDepuisExpiration = Math.round((Date.now() - codeExiste.expiresAt) / 1000)
      console.warn(`[verifierCode] ✗ Code expiré depuis ${secondesDepuisExpiration}s pour "${emailUser}"`)
      return res.status(400).json({ valide: false, message: `Code expiré depuis ${secondesDepuisExpiration} secondes. Demandez un nouveau code.` })
    }

    // ── SUCCÈS ─────────────────────────────────────────────────
    await prisma.codeVerification.update({
      where: { idCode: codeExiste.idCode },
      data: { estUtilise: true }
    })

    console.log(`[verifierCode] ✓ Email "${emailUser}" vérifié avec succès`)
    res.status(200).json({ valide: true, message: 'Email vérifié avec succès' })

  } catch (error) {
    console.error(`[verifierCode] Erreur serveur:`, error)
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// ETAPE 4 - Valider mot de passe
const validerPassword = (req, res) => {
  const { passwordUser } = req.body
  const validation = validerMotDePasse(passwordUser)
  if (!validation.valide) {
    return res.status(400).json({ valide: false, message: validation.message })
  }
  res.status(200).json({ valide: true, message: 'Mot de passe valide' })
}

// ETAPE 9 - Soumission finale
const register = async (req, res) => {
  try {
    const {
      nomUser, prenomUser, emailUser, passwordUser,
      numeroTelUser, idVille, idOperateur, roleUser,
      specialiteEnseignant, titreProfessionnelEnseignant, reseauxSociaux,
      niveauApprenant, idEtablissement,
      bioUser
    } = req.body

    // Vérification finale de tous les champs obligatoires
    const validNom = validerNom(nomUser)
    if (!validNom.valide) return res.status(400).json({ message: validNom.message })

    const validPrenom = validerNom(prenomUser)
    if (!validPrenom.valide) return res.status(400).json({ message: validPrenom.message })

    const validEmail = validerFormatEmail(emailUser)
    if (!validEmail.valide) return res.status(400).json({ message: validEmail.message })

    const validPassword = validerMotDePasse(passwordUser)
    if (!validPassword.valide) return res.status(400).json({ message: validPassword.message })

    if (!roleUser || !['ENSEIGNANT', 'APPRENANT'].includes(roleUser)) {
      return res.status(400).json({ message: 'Rôle invalide' })
    }

    // Vérifier que email n'existe pas déjà
    const userExiste = await prisma.user.findUnique({ where: { emailUser } })
    if (userExiste) return res.status(400).json({ message: 'Email déjà utilisé' })

    // Vérifier que l'email a bien été vérifié via le code
    const codeVerifie = await prisma.codeVerification.findFirst({
      where: {
        emailUser,
        estUtilise: true,
        expiresAt: { gt: new Date(Date.now() - 10 * 60 * 1000) }
      },
      orderBy: { dateCreation: 'desc' }
    })

    if (!codeVerifie) {
      return res.status(400).json({ message: 'Veuillez vérifier votre email avant de vous inscrire' })
    }

    // Vérifier que le numéro n'existe pas déjà
    if (numeroTelUser) {
      const telExiste = await prisma.user.findFirst({
        where: { numeroTelUser }
      })
      if (telExiste) {
        return res.status(400).json({ message: 'Ce numéro de téléphone est déjà utilisé' })
      }
    }

    // Vérifier format numéro téléphone
    if (numeroTelUser && idOperateur) {
      const operateur = await prisma.operateur.findUnique({
        where: { idOperateur }
      })

      if (!operateur) {
        return res.status(400).json({ message: 'Opérateur invalide' })
      }

      const operateursDuPays = await prisma.operateur.findMany({
        where: { idPays: operateur.idPays }
      })

      const validTel = validerTelephone(numeroTelUser, operateursDuPays)
      if (!validTel.valide) {
        return res.status(400).json({ message: validTel.message })
      }
    }

    // Hasher le mot de passe
    const hashedPassword = await bcrypt.hash(passwordUser, 12)

    // Transaction Prisma — tout ou rien
    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          nomUser, prenomUser, emailUser,
          passwordUser: hashedPassword,
          roleUser,
          numeroTelUser: numeroTelUser || null,
          bioUser: bioUser || null,
          idVille: idVille || null,
          idOperateur: idOperateur || null,
        }
      })

      if (roleUser === 'ENSEIGNANT') {
        const enseignant = await tx.enseignant.create({
          data: {
            idUser: user.idUser,
            specialiteEnseignant: specialiteEnseignant || null,
            titreProfessionnelEnseignant: titreProfessionnelEnseignant || null,
          }
        })

        if (reseauxSociaux && reseauxSociaux.length > 0) {
          await tx.reseauxSociaux.createMany({
            data: reseauxSociaux.map(rs => ({
              idEnseignant: enseignant.idEnseignant,
              plateformeRS: rs.plateformeRS,
              lienRS: rs.lienRS,
            }))
          })
        }
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

    // Générer JWT
    const token = jwt.sign(
      { idUser: result.idUser, roleUser: result.roleUser },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    )

    res.status(201).json({
      message: 'Inscription réussie',
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
// LOGIN
const login = async (req, res) => {
  try {
    const { emailUser, passwordUser } = req.body

    console.log('🔐 [login] Tentative de connexion → emailUser:', emailUser)

    if (!emailUser || !passwordUser) {
      console.warn('❌ [login] Email ou mot de passe manquant')
      return res.status(400).json({ message: 'Email et mot de passe obligatoires' })
    }

    // Vérifier email automatiquement
    const formatValide = validerFormatEmail(emailUser)
    console.log('📧 [login] Format email valide:', formatValide.valide)

    if (!formatValide.valide) {
      console.warn('❌ [login] Format email invalide')
      return res.status(400).json({ message: formatValide.message })
    }

    console.log('🔎 [login] Recherche utilisateur pour:', emailUser)
    const user = await prisma.user.findUnique({ where: { emailUser } })

    if (!user) {
      console.warn('❌ [login] Aucun utilisateur trouvé pour:', emailUser)
      return res.status(400).json({ message: 'Email ou mot de passe incorrect' })
    }

    console.log('✅ [login] Utilisateur trouvé:', { idUser: user.idUser, roleUser: user.roleUser })

    console.log('🔑 [login] Vérification du mot de passe...')
    const passwordValide = await bcrypt.compare(passwordUser, user.passwordUser)
    console.log('🔐 [login] Mot de passe valide:', passwordValide)

    if (!passwordValide) {
      console.warn('❌ [login] Mot de passe incorrect')
      return res.status(400).json({ message: 'Email ou mot de passe incorrect' })
    }

    console.log('🎫 [login] Génération du JWT...')
    const token = jwt.sign(
      { idUser: user.idUser, roleUser: user.roleUser },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    )

    console.log('✅ [login] Connexion réussie pour:', emailUser)
    res.status(200).json({
      message: 'Connexion réussie',
      token,
      user: {
        idUser: user.idUser,
        nomUser: user.nomUser,
        prenomUser: user.prenomUser,
        emailUser: user.emailUser,
        roleUser: user.roleUser,
      }
    })
  } catch (error) {
    console.error('💥 [login] Erreur serveur:', error.message)
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Vérifier email login dynamiquement
const verifierEmailLogin = async (req, res) => {
  try {
    const { emailUser } = req.body

    console.log('🔍 [verifierEmailLogin] Requête reçue → emailUser:', emailUser)

    const formatValide = validerFormatEmail(emailUser)
    console.log('📧 [verifierEmailLogin] Format email valide:', formatValide.valide)

    if (!formatValide.valide) {
      console.warn('❌ [verifierEmailLogin] Email invalide:', formatValide.message)
      return res.status(200).json({ existe: false, message: formatValide.message })
    }

    console.log('🔎 [verifierEmailLogin] Recherche dans BD pour:', emailUser)
    const user = await prisma.user.findUnique({ where: { emailUser } })

    if (!user) {
      console.warn('❌ [verifierEmailLogin] Aucun utilisateur trouvé pour:', emailUser)
      return res.status(200).json({ existe: false, message: 'Aucun compte associé à cet email' })
    }

    console.log('✅ [verifierEmailLogin] Utilisateur trouvé:', { idUser: user.idUser, emailUser: user.emailUser })
    res.status(200).json({ existe: true, message: 'Email trouvé' })
  } catch (error) {
    console.error('💥 [verifierEmailLogin] Erreur serveur:', error.message)
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}
// Demande de reset — envoie un code
const demanderResetPassword = async (req, res) => {
  try {
    const { emailUser } = req.body

    const user = await prisma.user.findUnique({ where: { emailUser } })
    if (!user) {
      return res.status(400).json({ message: 'Aucun compte associé à cet email' })
    }

    // Invalider les anciens codes
    await prisma.codeVerification.updateMany({
      where: { emailUser, estUtilise: false },
      data: { estUtilise: true }
    })

    const code = genererCode()
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000)

    await prisma.codeVerification.create({
      data: { codeVerification: code, emailUser, expiresAt }
    })

    await transporter.sendMail({
      from: `"LMS Platform" <${process.env.GMAIL_USER}>`,
      to: emailUser,
      subject: 'Réinitialisation de mot de passe',
      html: `
        <h2>Réinitialisation de votre mot de passe</h2>
        <p>Votre code de vérification est :</p>
        <h1 style="letter-spacing: 8px; color: #4F46E5;">${code}</h1>
        <p>Ce code expire dans <strong>10 minutes</strong>.</p>
        <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
      `
    })

    res.status(200).json({ message: 'Code envoyé sur votre email' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Vérifier le code reset (sans le marquer utilisé — on le garde pour l'étape suivante)
const verifierCodeReset = async (req, res) => {
  try {
    const { emailUser, code } = req.body

    if (!emailUser || !code) {
      return res.status(400).json({ message: 'Email et code obligatoires' })
    }

    const codeNormalise = String(code).trim()

    const codeExiste = await prisma.codeVerification.findFirst({
      where: { emailUser, codeVerification: codeNormalise, estUtilise: false },
      orderBy: { dateCreation: 'desc' }
    })

    if (!codeExiste) {
      return res.status(400).json({ message: 'Code incorrect ou déjà utilisé' })
    }

    if (codeExiste.expiresAt < new Date()) {
      return res.status(400).json({ message: 'Code expiré. Demandez un nouveau code.' })
    }

    res.status(200).json({ valide: true, message: 'Code valide' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Réinitialiser le mot de passe
const reinitialiserPassword = async (req, res) => {
  try {
    const { emailUser, code, newPassword } = req.body

    if (!emailUser || !code || !newPassword) {
      return res.status(400).json({ message: 'Tous les champs sont obligatoires' })
    }

    const validPassword = validerMotDePasse(newPassword)
    if (!validPassword.valide) {
      return res.status(400).json({ message: validPassword.message })
    }

    const codeNormalise = String(code).trim()

    const codeExiste = await prisma.codeVerification.findFirst({
      where: { emailUser, codeVerification: codeNormalise, estUtilise: false },
      orderBy: { dateCreation: 'desc' }
    })

    if (!codeExiste) {
      return res.status(400).json({ message: 'Code incorrect ou déjà utilisé' })
    }

    if (codeExiste.expiresAt < new Date()) {
      return res.status(400).json({ message: 'Code expiré. Recommencez.' })
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12)

    await prisma.$transaction([
      prisma.user.update({
        where: { emailUser },
        data: { passwordUser: hashedPassword }
      }),
      prisma.codeVerification.update({
        where: { idCode: codeExiste.idCode },
        data: { estUtilise: true }
      })
    ])

    res.status(200).json({ message: 'Mot de passe réinitialisé avec succès' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Valider le token (vérifier qu'il n'est pas expiré)
const validerToken = (req, res) => {
  // Si on arrive ici, le middleware authMiddleware a déjà validé le token
  res.status(200).json({ message: 'Token valide' })
}

module.exports = {
  validerNomPrenom,
  verifierEmailInscription,
  envoyerCodeVerification,
  verifierCode,
  validerPassword,
  register,
  login,
  verifierEmailLogin,
  // -- nouveau --
  demanderResetPassword,
  verifierCodeReset,
  reinitialiserPassword,
  validerToken,
}