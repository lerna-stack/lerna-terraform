#!/usr/bin/env bash

script_name="$(basename $0)"

readonly env_template_dir='env_template'

function main {
  case ${1:-generate-tfvars} in
    "check-module-template" )     check_module_template "$2" ;;
    "generate-module-template" )  generate_module_template "$2" ;;
    "check-tfvars" )      check_tfvars "$2" ;;
    "generate-tfvars" )   generate_tfvars "$2" ;;
    "debug" )             print_example_to_debug "$2" ;;
  esac
}

function check_module_template {
  local variables_file="$1"

  local tf_name="$(module_facility_tf_path_of "${variables_file}")"

  if ! diff --brief "${tf_name}" <(print_module_example "${variables_file}")
  then
    {
      echo ""
      echo "${variables_file} が変更されているため、${tf_name} の更新が必要です。"
      echo "'${script_name} generate-module-template \"${variables_file}\"' を実行してください。"
      return 1
    } >&2
  fi
}

function generate_module_template {
  local variables_file="$1"

  mkdir -p "${env_template_dir}"

  print_module_example "${variables_file}" > "$(module_facility_tf_path_of "${variables_file}")"
  return ${PIPESTATUS[1]}
}

function module_facility_tf_path_of {
  local variables_file="$1"

  local module_dir="$(dirname "${variables_file}")"
  local module_name="$(basename "${module_dir}")"

  echo "${env_template_dir}/facility-${module_name}.tf"
}

function print_module_example {
  local variables_file="$1"
  local module_dir="$(dirname "${variables_file}")"
  local module_name="$(basename "${module_dir}")"

    cat - << EOF | terraform fmt - | comment_out_module_vars
    module "${module_name//-/_}" {
      source = "../${module_dir}"
      $(construct_example "${variables_file}")
    }
EOF
  return ${PIPESTATUS[1]}
}

function comment_out_module_vars {
  awk '
    {
      if (match($0, /^(  )([^#].+)/, m) && !match(m[2], /^source =/)) {
        print m[1] "//" m[2]
      } else {
        print $0
      }
    }
  '
}

function check_tfvars {
  local variables_file="$1"

  local variable_file_dir="$(dirname "${variables_file}")"

  if ! diff --brief "${variable_file_dir}/terraform.tfvars.example" <(print_example "${variables_file}")
  then
    {
      echo ""
      echo "${variables_file} が変更されているため、terraform.tfvars.example の更新が必要です。"
      echo "'${script_name} generate-tfvars \"${variables_file}\"' を実行してください。"
      return 1
    } >&2
  fi
}

function generate_tfvars {
  local variables_file="$1"

  local variables_file_dir="$(dirname "${variables_file}")"

  print_example "${variables_file}" > "${variables_file_dir}/terraform.tfvars.example"
}

function construct_example {
  local variables_file="$1"

  cat "${variables_file}" | terraform fmt - \
      | awk '
        match($0, /^variable *"(.+)" *{$/, m) {
          variable_name = m[1]
        }
        match($0, /^ *default *= *(.+)$/, m) {
          default_value = m[1]
        }
        match($0, /^ *# *example *= *(.+)/, m) {
          example_value = m[1]
        }
        match($0, /^ *description *= *"(.+)"$/, m) {
          description = m[1]
        }
        $0 ~ /^}/ { # end of variable block
          example = example_value == "" ? default_value : example_value
          if (default_value == "") {
            description = "[必須] " description
          }
          if (example == "") {
            print "[ERROR] " variable_name " には default と example いずれも定義されていません" > "/dev/stderr"
          }
          print ""
          print "# " description
          print variable_name " = " example

          # Initialize
          variable_name = ""
          description   = ""
          default_value = ""
          example_value = ""
        }
        '
}

function print_example_to_debug {
  local variables_file="$1"

  construct_example "${variables_file}" | cat -n >&2
}

function print_example {
  local variables_file="$1"

  construct_example "${variables_file}" \
    | terraform fmt - \
    | sed -E -e 's@^([^#].+)@//\1@'
  return ${PIPESTATUS[1]}
}

main $@
