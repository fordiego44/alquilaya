# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Contexto

`alquilaya` es una aplicación Flutter para gestionar el alquiler de habitaciones de una vivienda.

Comandos: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run -d <device>`.

## Arquitectura

- Clean Architecture + Arquitectura Hexagonal (Ports & Adapters), aplicadas de forma pragmática.
- Capas separadas: dominio, aplicación, infraestructura y presentación.
- Las dependencias apuntan siempre hacia el dominio.
- El dominio no depende de Flutter ni de infraestructura.
- La lógica de negocio nunca vive dentro de Widgets.
- La persistencia se accede mediante puertos, para poder reemplazar el adaptador.

## Infraestructura: decisión pendiente

- La infraestructura **todavía no está decidida**.
- No introducir Supabase, Firebase, SQLite, REST, Spring Boot ni ningún otro backend o base de datos hasta que el usuario lo solicite.
- No añadir librerías externas sin justificar antes por qué son necesarias.

## Diseño

- SOLID cuando aporte valor; KISS, YAGNI y DRY como prioridad.
- Evitar sobreingeniería y abstracciones prematuras.
- No implementar funcionalidades especulativas.
- Evitar God Classes, Utils gigantes, `BaseRepository<T>` artificiales, Service Locator global y Singletons innecesarios.
- Preferir composición sobre herencia cuando corresponda.
- Nombres claros, null safety y tipos fuertes; evitar `dynamic` salvo necesidad real.

## Forma de trabajo

- Trabajar de forma incremental; no construir toda la aplicación de una sola vez.
- Priorizar pruebas de reglas de negocio y casos de uso.
- Antes de una decisión arquitectónica importante: explicar brevemente la recomendación y su trade-off.
- Si una decisión aún no es necesaria, indicarlo y posponerla.
