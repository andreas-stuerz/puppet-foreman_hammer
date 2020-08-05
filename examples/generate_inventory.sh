#!/bin/bash
# Create a Bolt inventory.yaml from a template file

DIRECTORY=`dirname $0`

inventory_path="${DIRECTORY}/inventory.yaml"
inventory_template_path="${DIRECTORY}/inventory.yaml.dist"

# backup
backup_dir="backup"
date=$(date +%Y-%m-%d_%H:%M:%S)
inventory_backup="${DIRECTORY}/inventory.yaml.${date}"

# regex to find tokens like <MY_SECRET> or <USERNAME>
token_regex="<(.*)>"

# tokens will be plain text
# secret tokens will be read in sensitivly and generate a bolt secret
secrets_prefix="SECRET_"

# eyaml encryption for bolt secrets
bolt_bin="bolt"

#### Subs
is_secret() {
  [[ "${1}" =~ ${secrets_prefix} ]] && return
  false
}

#### Main
echo "Generating inventory: ${inventory_path} from template: ${inventory_template_path}"

# create backup dir
mkdir -p ${backup_dir}

# if bolt inventory exists take a backup
if [ -e ${inventory_path} ]; then
  echo "Backup existing inventory to: ${inventory_backup}"
  cp ${inventory_path} ${inventory_backup}
fi

# copy template
cp ${inventory_template_path} ${inventory_path}

# parse tokens
tokens=$(grep -E "${token_regex}" ${inventory_template_path}| sed -E "s/.*(${token_regex}).*/\1/g"|sort|uniq)

# read in values for tokens
for token in ${tokens}; do
  var_name=$(echo $token|sed -E "s/${token_regex}/\1/g")

  if is_secret ${var_name}; then
    # read in sensitive
    read -s -p "Please enter your value for ${token}: " input
    echo
    # create a bolt secret
    input=$(${bolt_bin} secret encrypt ${input}|xargs|sed 's/ //g' )

  else
    # read in plain text
    read -p "Please enter your value for ${token}: " input
  fi

  # replace token in inventory
  ESCAPED_REPLACE=$(printf '%s\n' "${input}" | sed -e 's/[\/&]/\\&/g')
  sed -i '' "s/${token}/${ESCAPED_REPLACE}/g" ${inventory_path}
done








