#!/usr/bin/env bash

## en cas d'erreur, met fin au script immediatement
set -e

## supprime le warning au demarrage d'apache
echo "ServerName localhost" >> /etc/apache2/apache2.conf

## recherche l'expression puis remplace avec..
if [ -n "$APACHE_DOCUMENT_ROOT" ]; then
	sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
	sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
fi

## regarde si la command existe avant de l'executer
if command -v a2enmod; then
	a2enmod rewrite
fi

## pour finir, execute la CMD passe en parametere
exec "$@"
