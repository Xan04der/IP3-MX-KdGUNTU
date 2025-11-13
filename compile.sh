#!/bin/bash
# Script: Complete Custom Ubuntu ISO Builder
# Beschrijving: Downloadt Ubuntu ISO, past GRUB en manifest aan, en bouwt een aangepaste ISO.
# Compatibiliteit: Ubuntu/Debian systemen
# Vereist: sudo, wget, rsync, xorriso

set -e  # Stop script bij elke fout

# ==========================
# CONFIGURATIE
# ==========================
ISO_URL="https://releases.ubuntu.com/22.04.5/ubuntu-22.04.5-desktop-amd64.iso"
ISO_NAME="ubuntu-22.04.5-desktop-amd64.iso"
CUSTOM_ISO="ubuntu-22.04.5-custom-desktop.iso"

WORK_DIR_MNT="mnt"
WORK_DIR_CUSTOM="iso_custom"

# Manifest-bestanden
MANIFEST="$WORK_DIR_CUSTOM/casper/filesystem.manifest"
MANIFEST_NORMAL="$WORK_DIR_CUSTOM/casper/filesystem.manifest-remove"
MANIFEST_MIN="$WORK_DIR_CUSTOM/casper/filesystem.manifest-minimal-remove"

# GRUB-configuratie
GRUB_CFG="$WORK_DIR_CUSTOM/boot/grub/grub.cfg"

# ==========================
# ISO DOWNLOADEN
# ==========================
echo "=========================="
echo "[+] Controleer of ISO aanwezig is..."
if [ ! -f "$ISO_NAME" ]; then
    echo "[+] Downloaden van Ubuntu Desktop ISO..."
    wget -O "$ISO_NAME" "$ISO_URL"
else
    echo "[i] ISO-bestand bestaat al, overslaan download."
fi

# ==========================
# WERKMAP VOORBEREIDEN
# ==========================
echo "=========================="
echo "[+] Voorbereiden werkmap..."
rm -rf "$WORK_DIR_MNT" "$WORK_DIR_CUSTOM"
mkdir -p "$WORK_DIR_MNT" "$WORK_DIR_CUSTOM"
echo "[i] Werkmap klaar."

# ==========================
# ISO MOUNTEN EN KOPIËREN
# ==========================
echo "=========================="
echo "[+] Mounten van ISO..."
sudo mount -o loop "$ISO_NAME" "$WORK_DIR_MNT"

echo "[+] Kopiëren van ISO-inhoud naar werkmap..."
rsync -a "$WORK_DIR_MNT"/ "$WORK_DIR_CUSTOM"/

echo "[+] Ontkoppelen van ISO..."
sudo umount "$WORK_DIR_MNT"
echo "[i] ISO succesvol gekopieerd naar werkmap."

# ==========================
# GRUB AANPASSEN
# ==========================
echo "=========================="
if [ -f "$GRUB_CFG" ]; then
    echo "[+] Aanpassen van GRUB-configuratie..."
    sed -i 's/^set timeout=.*/set timeout=0/' "$GRUB_CFG"
    sed -i '0,/maybe-ubiquity/s/maybe-ubiquity/only-ubiquity/' "$GRUB_CFG"
    echo "✅ GRUB-configuratie aangepast."
else
    echo "⚠️ Waarschuwing: GRUB-configuratie niet gevonden, overslaan."
fi

# ==========================
# MANIFEST AANPASSEN
# ==========================
echo "=========================="
echo "[+] Minimal manifest aanpassen: LibreOffice behouden..."
sed -i '/libreoffice/d' "$MANIFEST_MIN"
sed -i '/uno-libs/d' "$MANIFEST_MIN"
sed -i '/python3-uno/d' "$MANIFEST_MIN"
sed -i '/ure/d' "$MANIFEST_MIN"

echo "[+] Voeg aangepaste minimal-inhoud toe aan normale removal file..."
cat "$MANIFEST_MIN" >> "$MANIFEST_NORMAL"
echo "✅ Manifest files aangepast."

# ==========================
# SQUASHFS IMAGES AANPASSEN
# ==========================
echo "=========================="
echo "[+] Uitpakken van squashfs..."
sudo unsquashfs -d squashfs-root "$WORK_DIR_CUSTOM/casper/filesystem.squashfs"

echo "[+] Start met vervangen van achtergronden, fallbacks en watermarks..."
echo "[i] Achtergronden vervangen..."

sudo cp warty-final-ubuntu.png squashfs-root/usr/share/backgrounds/warty-final-ubuntu.png
echo "   → warty-final-ubuntu.png vervangen"

sudo cp ubuntu-logo.png squashfs-root/usr/share/plymouth/ubuntu-logo.png
echo "   → ubuntu-logo.png vervangen"

sudo cp bgrt-fallback.png squashfs-root/usr/share/plymouth/themes/spinner/bgrt-fallback.png
echo "   → bgrt-fallback.png vervangen"

sudo cp watermark.png squashfs-root/usr/share/plymouth/themes/spinner/watermark.png
echo "   → watermark.png toegevoegd"

echo "[+] Script voor software-installatie toevoegen..."
sudo cp script.py squashfs-root/usr/local/bin/
sudo chmod +x squashfs-root/usr/local/bin/script.py
echo "✅ Installatiescript toegevoegd aan live systeem."

echo "[+] Nieuwe squashfs maken..."
sudo rm -f "$WORK_DIR_CUSTOM/casper/filesystem.squashfs"
sudo mksquashfs squashfs-root "$WORK_DIR_CUSTOM/casper/filesystem.squashfs" -comp xz -noappend

echo "[+] Opruimen tijdelijke bestanden..."
sudo rm -rf squashfs-root
echo "✅ Squashfs succesvol bijgewerkt."

# ==========================
# CUSTOM ISO BOUWEN
# ==========================
echo "=========================="
echo "[+] Building custom ISO..."
xorriso -as mkisofs \
  -r -V "UBUNTU_CUSTOM" \
  -o "$CUSTOM_ISO" \
  -J -joliet-long -l \
  -c boot.catalog \
  -b boot/grub/i386-pc/eltorito.img \
     -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e EFI/boot/bootx64.efi \
     -no-emul-boot \
  "$WORK_DIR_CUSTOM"/

echo "=========================="
echo "✅ Klaar! Je custom ISO staat in: $CUSTOM_ISO."
