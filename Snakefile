from scripts.clean_config import clean_config_paths
from scripts.get_samples import get_samples
import os

configfile: 'config.yaml'

paths = config['path']
paths = clean_config_paths(paths)
paths['base'] = os.getcwd()

# sample ids to run workflow with
ids = glob_wildcards(paths['fastq_R1'].replace('{id}', '{id,[^_]+}')).id

sample_details = get_samples(paths['sample_details'])

# remove samples not matching the chosen center
sample_details = {sample: detail for sample, detail in sample_details.items()
                    if detail.center == config['center']}


# remove ids not found in sample details
ids = [id for id in ids if id in sample_details]
# keep only samples from second batch (with b as last char)
ids = [id for id in ids if id[-1] == 'b']

# ids = ids[0:1]
print(f"{len(ids)} samples found to process")

subworkflows = config['main']['subworkflows']
if subworkflows is None:
    subworkflows = []

subw_outputs_dict = {}
subw_outputs = []

for subw in set(subworkflows):
    sub_path = 'subworkflows/{}.snake'.format(subw)
    if not os.path.exists(sub_path):
        continue

    subw_outputs_dict[subw] = []

    include: sub_path

    if len(subw_outputs_dict[subw]) == 0:
        continue

    subw_outputs.extend(subw_outputs_dict[subw])

onstart:
    print(f"{len(ids)} samples found...")

localrules:
    all

rule all:
    input:
        subworkflow_outputs = subw_outputs

rule clean:
    shell:
        'rm slurm_out/* || echo no slurm output\n'
