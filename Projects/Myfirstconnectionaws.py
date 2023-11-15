import configparser
import boto3


# Crea un objeto de configuración

config = configparser.ConfigParser()
config.read('G:\My Drive\Docs\Scripts\Github\repositorio\css\config.ini')

# Obtén las credenciales 
aws_access_key_id = config['default']['aws_access_key_id']
aws_secret_access_key = config['default']['aws_secret_access_key']
region_name = config['default']['region_name']


# Crea un objeto de sesión de AWS con las credenciales obtenidas del archivo

session = boto3.Session(
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name=region_name
)

# Crea un objeto de cliente de EC2

ec2 = session.client('ec2')

# Obtén la lista de instancias EC2

instances = ec2.describe_instances()

# Imprime la lista de instancias EC2

print(instances)




