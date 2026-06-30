-- CreateEnum
CREATE TYPE "Role" AS ENUM ('ENSEIGNANT', 'APPRENANT');

-- CreateEnum
CREATE TYPE "Niveau" AS ENUM ('DEBUTANT', 'INTERMEDIAIRE', 'AVANCE');

-- CreateEnum
CREATE TYPE "Statut" AS ENUM ('PUBLIE', 'BROUILLON');

-- CreateEnum
CREATE TYPE "TypeContenu" AS ENUM ('VIDEO', 'DOCUMENT', 'TEXTE');

-- CreateEnum
CREATE TYPE "StatutPaiement" AS ENUM ('GRATUIT', 'PAYANT', 'EN_ATTENTE');

-- CreateTable
CREATE TABLE "Pays" (
    "idPays" TEXT NOT NULL,
    "nomPays" TEXT NOT NULL,
    "codeIso" TEXT NOT NULL,
    "indicatif" TEXT NOT NULL,

    CONSTRAINT "Pays_pkey" PRIMARY KEY ("idPays")
);

-- CreateTable
CREATE TABLE "Ville" (
    "idVille" TEXT NOT NULL,
    "nomVille" TEXT NOT NULL,
    "idPays" TEXT NOT NULL,

    CONSTRAINT "Ville_pkey" PRIMARY KEY ("idVille")
);

-- CreateTable
CREATE TABLE "Operateur" (
    "idOperateur" TEXT NOT NULL,
    "nomOperateur" TEXT NOT NULL,
    "prefixes" TEXT[],
    "longueurNumero" INTEGER NOT NULL,
    "idPays" TEXT NOT NULL,

    CONSTRAINT "Operateur_pkey" PRIMARY KEY ("idOperateur")
);

-- CreateTable
CREATE TABLE "Etablissement" (
    "idEtablissement" TEXT NOT NULL,
    "nomEtablissement" TEXT NOT NULL,
    "typeEtablissement" TEXT NOT NULL,
    "idVille" TEXT NOT NULL,

    CONSTRAINT "Etablissement_pkey" PRIMARY KEY ("idEtablissement")
);

-- CreateTable
CREATE TABLE "User" (
    "idUser" TEXT NOT NULL,
    "nomUser" TEXT NOT NULL,
    "prenomUser" TEXT NOT NULL,
    "emailUser" TEXT NOT NULL,
    "passwordUser" TEXT NOT NULL,
    "roleUser" "Role" NOT NULL,
    "photoProfilUser" TEXT,
    "bioUser" TEXT,
    "numeroTelUser" TEXT,
    "dateInscriptionUser" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "idVille" TEXT,
    "idOperateur" TEXT,
    "paysIdPays" TEXT,

    CONSTRAINT "User_pkey" PRIMARY KEY ("idUser")
);

-- CreateTable
CREATE TABLE "Enseignant" (
    "idEnseignant" TEXT NOT NULL,
    "specialiteEnseignant" TEXT,
    "titreProfessionnelEnseignant" TEXT,
    "idUser" TEXT NOT NULL,

    CONSTRAINT "Enseignant_pkey" PRIMARY KEY ("idEnseignant")
);

-- CreateTable
CREATE TABLE "ReseauxSociaux" (
    "idReseauxSociaux" TEXT NOT NULL,
    "plateformeRS" TEXT NOT NULL,
    "lienRS" TEXT NOT NULL,
    "idEnseignant" TEXT NOT NULL,

    CONSTRAINT "ReseauxSociaux_pkey" PRIMARY KEY ("idReseauxSociaux")
);

-- CreateTable
CREATE TABLE "Apprenant" (
    "idApprenant" TEXT NOT NULL,
    "niveauApprenant" "Niveau",
    "idEtablissement" TEXT,
    "idUser" TEXT NOT NULL,

    CONSTRAINT "Apprenant_pkey" PRIMARY KEY ("idApprenant")
);

-- CreateTable
CREATE TABLE "Categorie" (
    "idCategorie" TEXT NOT NULL,
    "nomCategorie" TEXT NOT NULL,
    "iconeCategorie" TEXT,

    CONSTRAINT "Categorie_pkey" PRIMARY KEY ("idCategorie")
);

-- CreateTable
CREATE TABLE "Tag" (
    "idTag" TEXT NOT NULL,
    "nomTag" TEXT NOT NULL,

    CONSTRAINT "Tag_pkey" PRIMARY KEY ("idTag")
);

-- CreateTable
CREATE TABLE "Cours" (
    "idCours" TEXT NOT NULL,
    "titreCours" TEXT NOT NULL,
    "descriptionCours" TEXT NOT NULL,
    "prixCours" DOUBLE PRECISION,
    "estGratuitCours" BOOLEAN NOT NULL DEFAULT true,
    "imageCouvertureCours" TEXT,
    "niveauCours" "Niveau" NOT NULL,
    "statutCours" "Statut" NOT NULL DEFAULT 'BROUILLON',
    "dateCreationCours" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "idEnseignant" TEXT NOT NULL,
    "idCategorie" TEXT NOT NULL,

    CONSTRAINT "Cours_pkey" PRIMARY KEY ("idCours")
);

-- CreateTable
CREATE TABLE "CoursTag" (
    "idCoursTag" TEXT NOT NULL,
    "idCours" TEXT NOT NULL,
    "idTag" TEXT NOT NULL,

    CONSTRAINT "CoursTag_pkey" PRIMARY KEY ("idCoursTag")
);

-- CreateTable
CREATE TABLE "Module" (
    "idModule" TEXT NOT NULL,
    "titreModule" TEXT NOT NULL,
    "descriptionModule" TEXT NOT NULL,
    "ordreModule" INTEGER NOT NULL,
    "statutModule" "Statut" NOT NULL DEFAULT 'BROUILLON',
    "dateCreationModule" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "idCours" TEXT NOT NULL,

    CONSTRAINT "Module_pkey" PRIMARY KEY ("idModule")
);

-- CreateTable
CREATE TABLE "Contenu" (
    "idContenu" TEXT NOT NULL,
    "titreContenu" TEXT NOT NULL,
    "typeContenu" "TypeContenu" NOT NULL,
    "ordreContenu" INTEGER NOT NULL,
    "fichierUrl" TEXT,
    "lienExterne" TEXT,
    "texteContenu" TEXT,
    "dateCreationContenu" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "idModule" TEXT NOT NULL,

    CONSTRAINT "Contenu_pkey" PRIMARY KEY ("idContenu")
);

-- CreateTable
CREATE TABLE "Inscription" (
    "idInscription" TEXT NOT NULL,
    "dateInscription" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "statutPaiement" "StatutPaiement" NOT NULL DEFAULT 'GRATUIT',
    "dateCompletionCours" TIMESTAMP(3),
    "idApprenant" TEXT NOT NULL,
    "idCours" TEXT NOT NULL,

    CONSTRAINT "Inscription_pkey" PRIMARY KEY ("idInscription")
);

-- CreateTable
CREATE TABLE "Progression" (
    "idProgression" TEXT NOT NULL,
    "estTermine" BOOLEAN NOT NULL DEFAULT false,
    "dateCompletion" TIMESTAMP(3),
    "idApprenant" TEXT NOT NULL,
    "idModule" TEXT NOT NULL,

    CONSTRAINT "Progression_pkey" PRIMARY KEY ("idProgression")
);

-- CreateTable
CREATE TABLE "Notification" (
    "idNotification" TEXT NOT NULL,
    "messageNotification" TEXT NOT NULL,
    "estLuNotification" BOOLEAN NOT NULL DEFAULT false,
    "dateEnvoiNotification" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "idApprenant" TEXT NOT NULL,
    "idCours" TEXT NOT NULL,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("idNotification")
);

-- CreateIndex
CREATE UNIQUE INDEX "Pays_codeIso_key" ON "Pays"("codeIso");

-- CreateIndex
CREATE UNIQUE INDEX "User_emailUser_key" ON "User"("emailUser");

-- CreateIndex
CREATE UNIQUE INDEX "Enseignant_idUser_key" ON "Enseignant"("idUser");

-- CreateIndex
CREATE UNIQUE INDEX "Apprenant_idUser_key" ON "Apprenant"("idUser");

-- CreateIndex
CREATE UNIQUE INDEX "Tag_nomTag_key" ON "Tag"("nomTag");

-- AddForeignKey
ALTER TABLE "Ville" ADD CONSTRAINT "Ville_idPays_fkey" FOREIGN KEY ("idPays") REFERENCES "Pays"("idPays") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Operateur" ADD CONSTRAINT "Operateur_idPays_fkey" FOREIGN KEY ("idPays") REFERENCES "Pays"("idPays") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Etablissement" ADD CONSTRAINT "Etablissement_idVille_fkey" FOREIGN KEY ("idVille") REFERENCES "Ville"("idVille") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_idVille_fkey" FOREIGN KEY ("idVille") REFERENCES "Ville"("idVille") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_idOperateur_fkey" FOREIGN KEY ("idOperateur") REFERENCES "Operateur"("idOperateur") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_paysIdPays_fkey" FOREIGN KEY ("paysIdPays") REFERENCES "Pays"("idPays") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Enseignant" ADD CONSTRAINT "Enseignant_idUser_fkey" FOREIGN KEY ("idUser") REFERENCES "User"("idUser") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReseauxSociaux" ADD CONSTRAINT "ReseauxSociaux_idEnseignant_fkey" FOREIGN KEY ("idEnseignant") REFERENCES "Enseignant"("idEnseignant") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Apprenant" ADD CONSTRAINT "Apprenant_idUser_fkey" FOREIGN KEY ("idUser") REFERENCES "User"("idUser") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Apprenant" ADD CONSTRAINT "Apprenant_idEtablissement_fkey" FOREIGN KEY ("idEtablissement") REFERENCES "Etablissement"("idEtablissement") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Cours" ADD CONSTRAINT "Cours_idEnseignant_fkey" FOREIGN KEY ("idEnseignant") REFERENCES "Enseignant"("idEnseignant") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Cours" ADD CONSTRAINT "Cours_idCategorie_fkey" FOREIGN KEY ("idCategorie") REFERENCES "Categorie"("idCategorie") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CoursTag" ADD CONSTRAINT "CoursTag_idCours_fkey" FOREIGN KEY ("idCours") REFERENCES "Cours"("idCours") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CoursTag" ADD CONSTRAINT "CoursTag_idTag_fkey" FOREIGN KEY ("idTag") REFERENCES "Tag"("idTag") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Module" ADD CONSTRAINT "Module_idCours_fkey" FOREIGN KEY ("idCours") REFERENCES "Cours"("idCours") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Contenu" ADD CONSTRAINT "Contenu_idModule_fkey" FOREIGN KEY ("idModule") REFERENCES "Module"("idModule") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Inscription" ADD CONSTRAINT "Inscription_idApprenant_fkey" FOREIGN KEY ("idApprenant") REFERENCES "Apprenant"("idApprenant") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Inscription" ADD CONSTRAINT "Inscription_idCours_fkey" FOREIGN KEY ("idCours") REFERENCES "Cours"("idCours") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Progression" ADD CONSTRAINT "Progression_idApprenant_fkey" FOREIGN KEY ("idApprenant") REFERENCES "Apprenant"("idApprenant") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Progression" ADD CONSTRAINT "Progression_idModule_fkey" FOREIGN KEY ("idModule") REFERENCES "Module"("idModule") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_idApprenant_fkey" FOREIGN KEY ("idApprenant") REFERENCES "Apprenant"("idApprenant") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_idCours_fkey" FOREIGN KEY ("idCours") REFERENCES "Cours"("idCours") ON DELETE RESTRICT ON UPDATE CASCADE;
