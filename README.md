# Fiches

Appli de révision en un seul fichier HTML. Tu colles un cours en texte, elle génère des questions grâce à un modèle d'IA qui tourne **sur ton PC** (Ollama, modèle `qwen2.5:7b`). Tes fiches sont stockées dans le navigateur (localStorage) : rien ne part sur internet.

**Adresse :** https://elliotttt606.github.io/fiches-revision/

## Mise en route (PC)

1. Installer [Ollama](https://ollama.com) puis le modèle : `ollama pull qwen2.5:7b`.
2. Autoriser l'appli publiée à parler à Ollama : variable d'environnement `OLLAMA_ORIGINS=https://elliotttt606.github.io`, puis redémarrer Ollama.
   Les scripts `setup-windows.ps1` et `setup-mac.sh` font ces deux étapes automatiquement.
3. Ouvrir l'adresse ci-dessus dans Chrome ou Edge, et toujours passer par elle : les données sont liées à l'adresse.

## Sur iPhone

Safari > Partager > Sur l'écran d'accueil. La **génération ne marche pas sur le téléphone** : Ollama tourne sur le PC, et l'iPhone n'a pas d'Ollama à l'adresse `localhost:11434`. Pour réviser sur le téléphone : « Sauvegarder mes données » sur le PC, envoi du fichier par AirDrop, puis « Restaurer une sauvegarde » sur l'iPhone.

## Mettre à jour

Modifier `index.html`, puis :

```
git add -A
git commit -m "Description du changement"
git push
```

GitHub Pages republie en une à deux minutes. Si l'ancienne version reste affichée, recharger la page une seconde fois (le service worker récupère la nouvelle version au premier chargement).
