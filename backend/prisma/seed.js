const { PrismaClient } = require('@prisma/client')
const axios = require('axios')

const prisma = new PrismaClient()

const operateursParPays = {
  'MG': [
    { nom: 'Orange', prefixes: ['32', '37'], longueurNumero: 9 },
    { nom: 'Airtel', prefixes: ['33'], longueurNumero: 9 },
    { nom: 'Yas', prefixes: ['38', '34'], longueurNumero: 9 },
  ],
  'FR': [
    { nom: 'Orange', prefixes: ['06', '07'], longueurNumero: 10 },
    { nom: 'SFR', prefixes: ['06', '07'], longueurNumero: 10 },
    { nom: 'Bouygues', prefixes: ['06', '07'], longueurNumero: 10 },
    { nom: 'Free', prefixes: ['06', '07'], longueurNumero: 10 },
  ],
  'SN': [
    { nom: 'Orange', prefixes: ['77', '78'], longueurNumero: 9 },
    { nom: 'Free', prefixes: ['76', '75'], longueurNumero: 9 },
    { nom: 'Expresso', prefixes: ['70'], longueurNumero: 9 },
  ],
  'CI': [
    { nom: 'Orange', prefixes: ['07', '08'], longueurNumero: 10 },
    { nom: 'MTN', prefixes: ['05', '06'], longueurNumero: 10 },
    { nom: 'Moov', prefixes: ['01', '02'], longueurNumero: 10 },
  ],
  'CM': [
    { nom: 'MTN', prefixes: ['67', '68'], longueurNumero: 9 },
    { nom: 'Orange', prefixes: ['69', '65'], longueurNumero: 9 },
  ],
  'US': [
    { nom: 'AT&T', prefixes: ['2', '3', '4'], longueurNumero: 10 },
    { nom: 'Verizon', prefixes: ['5', '6', '7'], longueurNumero: 10 },
    { nom: 'T-Mobile', prefixes: ['8', '9'], longueurNumero: 10 },
  ],
  'GB': [
    { nom: 'EE', prefixes: ['07'], longueurNumero: 11 },
    { nom: 'Vodafone', prefixes: ['07'], longueurNumero: 11 },
    { nom: 'O2', prefixes: ['07'], longueurNumero: 11 },
  ],
  'CA': [
    { nom: 'Bell', prefixes: ['2', '3'], longueurNumero: 10 },
    { nom: 'Rogers', prefixes: ['4', '5'], longueurNumero: 10 },
    { nom: 'Telus', prefixes: ['6', '7'], longueurNumero: 10 },
  ],
}

const villesParPays = {
  'MG': ['Antananarivo', 'Toamasina', 'Fianarantsoa', 'Mahajanga', 'Toliara', 'Antsiranana', 'Antsirabe', 'Morondava'],
  'FR': ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice', 'Nantes', 'Strasbourg', 'Bordeaux', 'Lille', 'Rennes'],
  'SN': ['Dakar', 'Thiès', 'Saint-Louis', 'Ziguinchor', 'Kaolack', 'Mbour'],
  'CI': ['Abidjan', 'Bouaké', 'Daloa', 'Yamoussoukro', 'San-Pédro', 'Korhogo'],
  'CM': ['Douala', 'Yaoundé', 'Bamenda', 'Bafoussam', 'Garoua', 'Maroua'],
  'US': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego'],
  'GB': ['London', 'Manchester', 'Birmingham', 'Leeds', 'Glasgow', 'Liverpool', 'Bristol', 'Edinburgh'],
  'CA': ['Toronto', 'Montreal', 'Vancouver', 'Calgary', 'Edmonton', 'Ottawa', 'Quebec City', 'Winnipeg'],
}

const etablissementsParVille = {
  'Antananarivo': [
    { nom: 'Université d\'Antananarivo', type: 'UNIVERSITE' },
    { nom: 'Institut Supérieur de Technologie d\'Antananarivo', type: 'INSTITUT' },
    { nom: 'Ecole Supérieure Polytechnique d\'Antananarivo', type: 'ECOLE_SUPERIEURE' },
    { nom: 'Lycée Jules Ferry', type: 'LYCEE' },
  ],
  'Fianarantsoa': [
    { nom: 'Université de Fianarantsoa', type: 'UNIVERSITE' },
    { nom: 'Institut Supérieur de Technologie de Fianarantsoa', type: 'INSTITUT' },
    { nom: 'Lycée Rainibetsimisaraka', type: 'LYCEE' },
  ],
  'Toamasina': [
    { nom: 'Université de Toamasina', type: 'UNIVERSITE' },
    { nom: 'Institut Supérieur de Technologie de Toamasina', type: 'INSTITUT' },
  ],
  'Paris': [
    { nom: 'Université Paris-Sorbonne', type: 'UNIVERSITE' },
    { nom: 'École Polytechnique', type: 'ECOLE_SUPERIEURE' },
    { nom: 'HEC Paris', type: 'ECOLE_SUPERIEURE' },
    { nom: 'Sciences Po Paris', type: 'INSTITUT' },
  ],
  'Lyon': [
    { nom: 'Université Claude Bernard Lyon 1', type: 'UNIVERSITE' },
    { nom: 'École Centrale de Lyon', type: 'ECOLE_SUPERIEURE' },
    { nom: 'INSA Lyon', type: 'ECOLE_SUPERIEURE' },
  ],
  'Dakar': [
    { nom: 'Université Cheikh Anta Diop', type: 'UNIVERSITE' },
    { nom: 'École Supérieure Polytechnique de Dakar', type: 'ECOLE_SUPERIEURE' },
  ],
  'Abidjan': [
    { nom: 'Université Félix Houphouët-Boigny', type: 'UNIVERSITE' },
    { nom: 'Institut National Polytechnique Félix Houphouët-Boigny', type: 'INSTITUT' },
  ],
}

async function main() {
  console.log('Démarrage du seed...')

  console.log('Récupération des pays depuis l\'API...')
  const response = await axios.get('https://restcountries.com/v3.1/all?fields=name,cca2,idd')
  const paysData = response.data

  console.log(`${paysData.length} pays récupérés`)

  let paysCount = 0
  let villesCount = 0
  let etablissementsCount = 0
  let operateursCount = 0

  for (const paysDonnee of paysData) {
    const codeIso = paysDonnee.cca2
    const nomPays = paysDonnee.name.common
    const indicatif = paysDonnee.idd?.root
      ? paysDonnee.idd.root + (paysDonnee.idd.suffixes?.[0] || '')
      : ''

    if (!indicatif) continue

    // Créer le pays
    let pays = await prisma.pays.findUnique({ where: { codeIso } })

    if (!pays) {
      pays = await prisma.pays.create({
        data: { nomPays, codeIso, indicatif }
      })
      paysCount++
    }

    // Ajouter les opérateurs
    if (operateursParPays[codeIso]) {
      for (const op of operateursParPays[codeIso]) {
        const opExiste = await prisma.operateur.findFirst({
          where: { idPays: pays.idPays, nomOperateur: op.nom }
        })
        if (!opExiste) {
          await prisma.operateur.create({
            data: {
              idPays: pays.idPays,
              nomOperateur: op.nom,
              prefixes: op.prefixes,
              longueurNumero: op.longueurNumero,
            }
          })
          operateursCount++
        }
      }
    }

    // Ajouter les villes
    if (villesParPays[codeIso]) {
      for (const nomVille of villesParPays[codeIso]) {
        let ville = await prisma.ville.findFirst({
          where: { idPays: pays.idPays, nomVille }
        })

        if (!ville) {
          ville = await prisma.ville.create({
            data: { idPays: pays.idPays, nomVille }
          })
          villesCount++
        }

        // Ajouter les établissements
        if (etablissementsParVille[nomVille]) {
          for (const etab of etablissementsParVille[nomVille]) {
            const etabExiste = await prisma.etablissement.findFirst({
              where: { idVille: ville.idVille, nomEtablissement: etab.nom }
            })
            if (!etabExiste) {
              await prisma.etablissement.create({
                data: {
                  idVille: ville.idVille,
                  nomEtablissement: etab.nom,
                  typeEtablissement: etab.type,
                }
              })
              etablissementsCount++
            }
          }
        }
      }
    }
  }

  console.log(`✓ ${paysCount} pays ajoutés`)
  console.log(`✓ ${operateursCount} opérateurs ajoutés`)
  console.log(`✓ ${villesCount} villes ajoutées`)
  console.log(`✓ ${etablissementsCount} établissements ajoutés`)
  console.log('Seed terminé avec succès !')
}

main()
  .catch((e) => {
    console.error('Erreur seed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })