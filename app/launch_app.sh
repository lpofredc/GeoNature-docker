#!/bin/bash
script_home_dir=/geonature
mnt_bootstrap_dir=/mnt_bootstrap_files
bootstrap_dir=/bootstrap_files
geonature_user=geonatureadmin
cd $script_home_dir

verbose=1

. /usr/local/utils.lib.sh
# . config/settings.ini

BASE_DIR=$(readlink -e "${0%/*}")

_verbose_echo "${green}launch_app - ${nocolor}Droits sur le répertoire ${script_home_dir}"
sudo chown -R ${geonature_user}. ${script_home_dir}

_verbose_echo "${green}launch_app - ${nocolor}Attente de la base de données..."
wait_for_restart db:5432

## Start supervisor
_verbose_echo "${green}launch_app - ${nocolor}Copie de la conf de supervisor (si existe)"
mkdir -p ${script_home_dir}/sysfiles/supervisor
sudo cp ${script_home_dir}/sysfiles/supervisor/*.conf /etc/supervisor/conf.d/

_verbose_echo "${green}launch_app - ${nocolor}Copie des scripts du volume vers ${bootstrap_dir} et droits"
sudo cp -R ${mnt_bootstrap_dir}/* ${bootstrap_dir}/
sudo chmod -R a+rx ${bootstrap_dir}

_verbose_echo "${green}launch_app - ${nocolor}Vérifie si on doit lancer supervisor en tâche de fond"
if [[ ! -f /$script_home_dir/sysfiles/usershub_installed ]] || [[ ! -f /$script_home_dir/sysfiles/taxhub_installed ]] || [[ ! -f /$script_home_dir/sysfiles/geonature_installed ]] || [[ ! -f /$script_home_dir/sysfiles/atlas_installed ]]; then
    _verbose_echo "${green}launch_app - ${nocolor}Lancement de supervisor en tâche de fond"
    sudo /usr/bin/supervisord &

    _verbose_echo "${green}launch_app - ${nocolor}Vérification des installations des applications"
    if [[ ! -f /$script_home_dir/sysfiles/usershub_installed ]]; then
        _verbose_echo "${green}launch_app - ${nocolor}Installation d'Usershub nécessaire"
        /bin/bash ${bootstrap_dir}/scripts/uh-install.sh
    fi
    if [[ ! -f /$script_home_dir/sysfiles/taxhub_installed ]]; then
        _verbose_echo "${green}launch_app - ${nocolor}Installation de TaxHub nécessaire"
        /bin/bash ${bootstrap_dir}/scripts/th-install.sh
    fi
    if [[ ! -f /$script_home_dir/sysfiles/geonature_installed ]]; then
        _verbose_echo "${green}launch_app - ${nocolor}Installation de GeoNature nécessaire"
        /bin/bash ${bootstrap_dir}/scripts/gn-install.sh
    fi
    if [[ ! -f /$script_home_dir/sysfiles/atlas_installed ]]; then
        _verbose_echo "${green}launch_app - ${nocolor}Installation d'Atlas nécessaire"
        /bin/bash ${bootstrap_dir}/scripts/ga-install.sh
    fi
    _verbose_echo "${green}launch_app - ${nocolor}Arrêt de supervisor en tâche de fond"
    sudo supervisorctl stop all
    sleep 5
    sudo supervisorctl shutdown
    sleep 5
fi

if [[ ! -z $1 ]]; then
    _verbose_echo "${green}launch_app - ${nocolor}Lancement d'un bash"
    /bin/bash -c $1
else
    _verbose_echo "${green}launch_app - ${nocolor}Relacement de supervisor en tâche principale"
    sudo /usr/bin/supervisord
fi
