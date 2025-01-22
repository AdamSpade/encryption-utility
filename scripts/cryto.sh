#!/bin/sh

## Configuration
JASYPT_VERSION="1.9.3"
JASYPT_JAR="jasypt-${JASYPT_VERSION}.jar"
JASYPT_PATH="./lib/${JASYPT_JAR}"
DOWNLOAD_PATH=https://repo1.maven.org/maven2/org/jasypt/jasypt

ALGORITHM="PBEWITHHMACSHA512ANDAES_256"
ITERATIONS=1000
ALGORITHM_CLASS=org.jasypt.intf.cli.AlgorithmRegistryCLI
ENCRYPT_CLASS=org.jasypt.intf.cli.JasyptPBEStringEncryptionCLI
DECRYPT_CLASS=org.jasypt.intf.cli.JasyptPBEStringDecryptionCLI
RANDOM_CLASS=org.jasypt.iv.RandomIvGenerator

## Options Menu
usage_menu() {
	echo "Note: Secret key should be stored as an environmental variable named DECRYPT_KEY"
	echo "Usage: $0 [OPTIONS]"
	echo "Options:"
	echo " -e, --encrypt    Encrypt a password"
	echo " -d, --decrypt    Decrypt a password"
	echo " -p, --password   Password to encrypt/decrypt"
	echo " -h, --help       Display this help message"
	echo
	echo "How to use commands:"
	echo "$0 -e -p <decrypted_password>"
	echo "$0 -d -p <encrypted_password>"
}

## Validate that DECRYPT_KEY variable exists
check_key() {
	if [ -n "$DECRYPT_KEY" ]; then
		echo "DECRYPT_KEY is set"
	else
		echo "DECRYPT_KEY is not set properly. Please set an environmental variable titled DECRYPT_KEY."
		echo 1
	fi
}

## Download Jasypt Jar if it does not already exist
check_jasypt() {
	if [ -f "$JASYPT_PATH" ]; then
		echo "$JASYPT_PATH exists, proceeding..."
	else
		echo "$JASYPT_PATH does not exists., downloading from web..."
		curl -k --output "$JASYPT_PATH" "${DOWNLOAD_PATH}/${JASYPT_VERSION}/${JASYPT_JAR}"
	fi
}

encrypt_password() {
	local PASSWORD=$1
	
	java -cp "$JASYPT_PATH" \
	"$ENCRYPT_CLASS" \
	input="$PASSWORD" \
	password="${DECRYPT_KEY}" \
	algorithm="$ALGORITHM" \
	keyObtentionIterations="$ITERATIONS" \
	ivGeneratorClassName="$RANDOM_CLASS"
}

decrypt_password() {
	local ENCRYPTED=$1
	
	java -cp "$JASYPT_PATH" \
	"$DECRYPT_CLASS" \
	input="$ENCRYPTED" \
	password="${DECRYPT_KEY}" \
	algorithm="$ALGORITHM" \
	keyObtentionIterations="$ITERATIONS" \
	ivGeneratorClassName="$RANDOM_CLASS"
}

## Check if a parameter has been passed
if [ $# -eq 0 ]; then
	usage_menu
	exit 1
fi

## Main script logic
MODE=""
PASSWORD=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-e|--encrypt)
			MODE="encrypt"
			shift
			;;
		-d|--decrypt)
			MODE="decrypt"
			shift
			;;
		-l|--list)
			MODE="list"
			shift
			;;
		-p|--password)
			if [ -z "$2" ] || [[ "$2" == -* ]]; then
				echo "Error: -p|--password requires a password value"
				usage_menu
				exit 1
			fi
			PASSWORD="$2"
			shift 2
			;;
		-h|--help)
			usage_menu
			exit 0
			;;
		*)
			echo "Error: Invalid option $1"
			usage_menu
			exit 1
			;;
	esac
done

if [ -z "$MODE" ]; then
	echo "Error: Please specify mode:"
	echo "	-e|--encrypt"
	echo "	-d|--decrypt"
	echo "  -h|--help for options"
	exit 1
fi

if [ -z "$PASSWORD" ]; then
	echo "Error: Please provide a password using -p option"
	usage_menu
	exit 1
fi

check_key
check_jasypt

case $MODE in 
	encrypt)
		echo "Encrypted password:"
		encrypt_password "$PASSWORD"
		;;
	decrypt)
		echo "Decrypted password:"
		decrypt_password "$PASSWORD"
		;;
esac


