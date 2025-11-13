#!/usr/bin/env python3
import os
import subprocess

SOFTWARES = {
    "Google Chrome": {
        "check": "google-chrome",
        "install": (
            "wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb && "
            "sudo apt install -y /tmp/chrome.deb && "
            "rm /tmp/chrome.deb"
        )
    },
    "Git": {
        "check": "git",
        "install": "sudo apt-get install -y git"
    },
    "VSCode": {
        "check": "code",
        "install": "sudo snap install code --classic"
    },
    "IntelliJ IDEA": {
        "check": "intellij-idea-community",
        "install": "sudo snap install intellij-idea-community --classic"
    },
    "Rider": {
        "check": "rider",
        "install": "sudo snap install rider --classic"
    }
}


def is_installed(cmd):
    result = subprocess.run(["which", cmd],
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL)
    if result.returncode == 0:
        return True
    result = subprocess.run(f"snap list | grep -w {cmd}",
                            shell=True,
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL)
    return result.returncode == 0


def filter_not_installed():
    return {n: s for n, s in SOFTWARES.items() if not is_installed(s["check"])}


def show_menu(choices):
    selected = set()
    while True:
        os.system("clear")
        print("=== Ubuntu Software Installer ===\n")
        print("Gebruik nummers om aan/uit te vinken. ENTER om te installeren.\n")

        for i, name in enumerate(choices, 1):
            mark = "[x]" if name in selected else "[ ]"
            print(f"{i}. {mark} {name}")

        print("\nENTER = installeren, nummer = togglen, q = afsluiten")
        choice = input("> ").strip()

        if choice == "":
            return list(selected)
        elif choice.lower() == "q":
            return []
        elif choice.isdigit():
            idx = int(choice) - 1
            if 0 <= idx < len(choices):
                name = list(choices)[idx]
                selected ^= {name}


def install_selected(selected):
    for name in selected:
        cmd = SOFTWARES[name]["install"]
        print(f"\n🔧 Installeren van {name}...\n")
        os.system(cmd)
    print("\n✅ Installatie voltooid!")


def main():
    print("🔄 Bijwerken van pakketlijsten...")
    os.system("sudo apt-get update -y > /dev/null")

    available = filter_not_installed()
    if not available:
        print("🎉 Alles is al geïnstalleerd!")
        return

    selected = show_menu(list(available.keys()))
    if not selected:
        print("Geen selectie gemaakt. Afsluiten.")
        return

    install_selected(selected)


if __name__ == "__main__":
    main()

