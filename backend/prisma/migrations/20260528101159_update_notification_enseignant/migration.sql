-- DropForeignKey
ALTER TABLE "Notification" DROP CONSTRAINT "Notification_idApprenant_fkey";

-- AlterTable
ALTER TABLE "Notification" ADD COLUMN     "idEnseignant" TEXT,
ALTER COLUMN "idApprenant" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_idApprenant_fkey" FOREIGN KEY ("idApprenant") REFERENCES "Apprenant"("idApprenant") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_idEnseignant_fkey" FOREIGN KEY ("idEnseignant") REFERENCES "Enseignant"("idEnseignant") ON DELETE SET NULL ON UPDATE CASCADE;
