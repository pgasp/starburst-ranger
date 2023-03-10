#!/usr/bin/env python3
import subprocess
from argparse import ArgumentParser, Namespace
from os import environ

import logging
import requests
import yaml
from sys import stdout
from typing import Any, Dict, List

SERVICE_DEFINITION: str = "starburst-enterprise"
RANGER_ADDRESS: str = "http://localhost:6080"


def read_manifest(path: str) -> Any:
    with open(path, "rb") as manifest:
        return yaml.load(manifest, Loader=yaml.SafeLoader)


def find_by_name(items: List[Dict[str, Any]], item_name: str) -> Dict[str, Any]:
    matching = list(filter(lambda item: item["name"] == item_name, items))
    assert (
            len(matching) == 1
    ), "Expected 1 item with name '{}', found {}".format(
        item_name, len(matching)
    )
    return matching[0]


def create_user(username: str, password: str) -> None:
    admin_user = "admin"
    admin_password = environ["RANGER__rangerAdmin_password"]
    if admin_user == username and admin_password != password:
        message = (f"Datasource password for \"{username}\" is not equal to "
                   f"\"{admin_user}\" password. When using \"{admin_user}\" "
                   f"as a datasource user it has to have the same password "
                   f"as the admin.passwords.admin property defined in Helm values file or "
                   f"the RANGER__rangerAdmin_password environmental variable.")
        raise RuntimeError(message)
    elif admin_user == username:
        return
    else:
        # if refactoring to Python request, take additional time as
        # post() method constantly returns 404 for create_user()
        subprocess.check_call(
            [
                "./create-user.sh",
                "-l", RANGER_ADDRESS,
                "-u", admin_user,
                "-p", admin_password,
                username,
                password,
            ],
            cwd="/scripts"
        )


def create_service_definition(username: str, password: str) -> None:
    subprocess.check_call(
        [
            "./create-service-def.py",
            "--url", RANGER_ADDRESS,
            "--username", username,
            "--password", password,
        ],
        cwd=environ["RANGER_BASE"]
    )


def get_service(username: str, password: str, service_name: str) -> Any:
    logging.info("Getting service [%s]", service_name)
    response: requests.models.Response = requests.get(
        url=RANGER_ADDRESS + "/service/public/v2/api/service/name/" + service_name,
        auth=(username, password)
    )
    assert (response.status_code in (200, 404)
            ), "Incorrect response while getting service: " + response.text
    if response.status_code == 404:
        return {}
    return response.json()


def create_or_update_service(
        coordinator_url: str,
        username: str,
        password: str,
        service_name: str) -> None:
    service: Dict[str, Any] = get_service(username, password, service_name)
    if service:
        update_service(coordinator_url, username, password, service)
    else:
        create_service(coordinator_url, username, password, service_name)


def create_service(
        coordinator_url: str,
        username: str,
        password: str,
        service_name: str) -> None:
    logging.info("Creating service [%s] for Starburst Enterprise [%s]",
                 service_name, coordinator_url)
    service: Dict[str, Any] = configure_service(coordinator_url, username, service_name)
    response: requests.models.Response = requests.post(
        url=RANGER_ADDRESS + "/service/public/v2/api/service",
        json=service,
        auth=(username, password)
    )
    assert response.status_code == 200, "Incorrect response for create_service: " + response.text
    logging.info("Service [%s] created successfully", service_name)


def update_service(
        coordinator_url: str,
        username: str,
        password: str,
        service: Any) -> None:
    name: str = service["name"]
    logging.info("Updating service [%s] for Starburst Enterprise [%s], Ranger url: [%s]",
                 name, coordinator_url, RANGER_ADDRESS)
    updated_service: Dict[str, Any] = configure_service(coordinator_url, username, name)
    updated_service["tagVersion"] = service["tagVersion"]
    updated_service["policyVersion"] = service["policyVersion"]
    response: requests.models.Response = requests.put(
        url=RANGER_ADDRESS + "/service/public/v2/api/service/" + str(service['id']),
        json=updated_service,
        auth=(username, password)
    )
    assert response.status_code == 200, "Incorrect response for update_service: " + response.text
    logging.info("Service [%s] updated successfully", name)


def configure_service(coordinator_url: str, username: str, service_name: str) -> Dict[str, Any]:
    return {
        "tagVersion": 1,
        "policyVersion": 1,
        "configs": {
            "jdbc.driverClassName": "io.trino.jdbc.TrinoDriver",
            "jdbc.url": coordinator_url,
            "resource-lookup": "true",
            "username": username,
        },
        "type": SERVICE_DEFINITION,
        "name": service_name,
        "description": "Created by Starburst Platform auto-configure script, do not modify",
    }


def config_access_control(config: Any) -> None:
    service_definition_created: bool = False
    for data_source in config["datasources"]:
        username: str = data_source["username"]
        password: str = data_source["password"]
        service: str = data_source["name"]
        coordinator_url: str = "jdbc:trino://{}:{}".format(data_source["host"], data_source["port"])
        create_user(username, password)
        if not service_definition_created:
            create_service_definition(username, password)
            service_definition_created = True
        create_or_update_service(coordinator_url, username, password, service)


def parse_params() -> Namespace:
    parser = ArgumentParser(
        description="Apply Ranger services configuration from config file.")
    parser.add_argument("node_type", choices=["ranger-admin", "ranger-usersync", "ranger-tagsync"])
    parser.add_argument(
        "-c",
        "--config",
        default="/config/datasources.yaml",
        help="location of config file, default %(default)s")
    return parser.parse_args()


def config_ranger(args: Namespace) -> None:
    config: Any = read_manifest(args.config)
    if args.node_type == "ranger-admin":
        config_access_control(config)


if __name__ == "__main__":
    logging.basicConfig(
        stream=stdout,
        level=logging.INFO,
        format='%(asctime)s %(levelname)s: %(message)s')
    config_ranger(parse_params())
