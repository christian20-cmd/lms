const validator = require('validator')

const validerFormatEmail = (email) => {
  if (!email) return { valide: false, message: 'Email est obligatoire' }
  if (!validator.isEmail(email)) return { valide: false, message: 'Format email invalide' }
  return { valide: true }
}

const validerMotDePasse = (motDePasse) => {
  if (!motDePasse) return { valide: false, message: 'Mot de passe est obligatoire' }
  if (motDePasse.length < 8) return { valide: false, message: 'Minimum 8 caractères' }
  if (!/[A-Z]/.test(motDePasse)) return { valide: false, message: 'Au moins une majuscule obligatoire' }
  if (!/[a-z]/.test(motDePasse)) return { valide: false, message: 'Au moins une minuscule obligatoire' }
  if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(motDePasse)) return { valide: false, message: 'Au moins un caractère spécial obligatoire' }
  return { valide: true }
}

const validerTelephone = (telephone, operateurs) => {
  if (!telephone) return { valide: false, message: 'Téléphone est obligatoire' }

  const numeroSansEspaces = telephone.replace(/\s/g, '')

  if (operateurs.length === 0) return { valide: true }

  const longueurAttendue = operateurs[0].longueurNumero
  if (numeroSansEspaces.length !== longueurAttendue) {
    return { valide: false, message: `Le numéro doit contenir exactement ${longueurAttendue} chiffres` }
  }

  const prefixeValide = operateurs.some(op =>
    op.prefixes.some(prefix => numeroSansEspaces.startsWith(prefix))
  )

  if (!prefixeValide) {
    const tousLesPrefixes = [...new Set(operateurs.flatMap(op => op.prefixes))]
    return { valide: false, message: `Le numéro doit commencer par : ${tousLesPrefixes.join(', ')}` }
  }

  const operateurDetecte = operateurs.find(op =>
    op.prefixes.some(prefix => numeroSansEspaces.startsWith(prefix))
  )

  return { valide: true, operateur: operateurDetecte?.nomOperateur }
}

const validerNom = (nom) => {
  if (!nom) return { valide: false, message: 'Ce champ est obligatoire' }
  if (nom.trim().length < 2) return { valide: false, message: 'Minimum 2 caractères' }
  if (/[0-9]/.test(nom)) return { valide: false, message: 'Aucun chiffre autorisé' }
  return { valide: true }
}

module.exports = { validerFormatEmail, validerMotDePasse, validerTelephone, validerNom }