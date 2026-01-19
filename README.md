# FretFly – mobilní aplikace pro kytaristy

FretFly je mobilní aplikace vyvinutá v prostředí **Flutter**, jejímž cílem je poskytnout kytaristům přehledné a funkční nástroje pro každodenní cvičení. Projekt vznikl jako **maturitní práce** a zaměřuje se na implementaci klíčových hudebních pomůcek s důrazem na jednoduchost použití, technickou správnost a moderní architekturu aplikace.

---
## Odkaz na videoprezentaci
https://www.youtube.com/watch?v=cUAVxCkiSAY
## Obsah
- [Přehled projektu](#přehled-projektu)  
- [Hlavní funkce](#hlavní-funkce)  
- [Použité technologie](#použité-technologie)  
- [Architektura řešení](#architektura-řešení)  
- [Cíle projektu](#cíle-projektu)  
- [English version](#english-version)

---

## Přehled projektu
Aplikace FretFly slouží jako digitální pomocník pro začínající i pokročilé kytaristy.

Projekt klade důraz na:
- srozumitelné uživatelské rozhraní,  
- technicky korektní zpracování zvuku,  
- stabilní ukládání uživatelských dat v cloudu.

---

## Hlavní funkce
- **Ladička** – detekce frekvence tónu pomocí metody *zero-crossing detection*.  
- **Metronom** – nastavitelný rozsah BPM (40–240) a volba taktu.  
- **Databáze akordů** – vizualizace hmatníku, vyhledávání a filtrování akordů.  
- **Uživatelský účet** – autentizace přes e-mail a ukládání statistik.  
- **Sledování pokroku** – počet naučených akordů, série aktivních dní.  
- **Podpora světlého a tmavého režimu**.

---

## Použité technologie
- **Flutter / Dart** – vývoj multiplatformní mobilní aplikace.  
- **Firebase Authentication** – správa uživatelských účtů.  
- **Cloud Firestore** – ukládání dat aplikace a statistik.  
- **Microphone API** – snímání zvuku z mikrofonu zařízení.  
- **Git** – správa verzí a vývoje projektu.

---

## Architektura řešení
Aplikace je navržena jako **klientská mobilní aplikace** s napojením na cloudové služby Firebase. Logika zpracování zvuku probíhá lokálně na zařízení, zatímco uživatelská data jsou ukládána do vzdálené databáze, což umožňuje jejich synchronizaci mezi zařízeními a dlouhodobou archivaci.

Důraz byl kladen na:
- oddělení prezentační a aplikační logiky,  
- čitelnost kódu a jeho budoucí rozšiřitelnost,  
- minimalizaci závislostí na externích knihovnách.

---

## Cíle projektu
Hlavním cílem projektu bylo vytvořit **funkční a technicky kvalitní mobilní aplikaci**, která:
- kombinuje nejdůležitější nástroje pro kytaristy, 
- slouží jako praktická ukázka schopností práce s Flutterem, Firebase a zpracováním zvuku v reálném čase.

---

# English version

## FretFly – Mobile Application for Guitarists

FretFly is a mobile application developed using **Flutter**, designed to provide guitarists with clear and functional tools for everyday practice. The project was created as a **final school thesis** and focuses on implementing essential musical utilities with an emphasis on usability, technical correctness, and modern application architecture.

---

## Table of Contents
- [Project Overview](#project-overview)  
- [Key Features](#key-features)  
- [Technologies Used](#technologies-used)  
- [System Architecture](#system-architecture)  
- [Project Goals](#project-goals)

---

## Project Overview
FretFly serves as a digital assistant for both beginner and advanced guitarists.

The project emphasizes:
- a clear and intuitive user interface,  
- technically accurate audio processing,  
- reliable cloud-based data storage.

---

## Key Features
- **Tuner** – frequency detection using the *zero-crossing detection* method.  
- **Metronome** – adjustable BPM range (40–240) and time signature selection.  
- **Chord Database** – fretboard visualization with search and filtering options.  
- **User Accounts** – email-based authentication and profile management.  
- **Progress Tracking** – learned chords count and daily practice streaks.  
- **Light and Dark Mode** support.

---

## Technologies Used
- **Flutter / Dart** – cross-platform mobile application development.  
- **Firebase Authentication** – user account management.  
- **Cloud Firestore** – application data and statistics storage.  
- **Microphone API** – audio input processing.  
- **Git** – version control system.

---

## System Architecture
The application is designed as a **client-side mobile solution** integrated with Firebase cloud services. Audio processing is performed locally on the device, while user data is stored in a remote database, enabling synchronization across devices and long-term persistence.

Key architectural principles include:
- separation of presentation and application logic,  
- code readability and future extensibility,  
- minimal reliance on external dependencies.

---

## Project Goals
The main goal of the project was to create a **functional and technically sound mobile application** that:
- combines essential tools for guitar practice,  
- demonstrates practical skills in Flutter development, Firebase integration, and real-time audio processing.

The project represents a comprehensive student work combining **mobile application development, audio signal processing, and user interface design**.
