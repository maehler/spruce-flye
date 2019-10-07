configfile: 'config.yaml'

localrules: index_fasta

rule read_subsampling:
    input:
        fasta=config['reads'],
        index='{fasta}.fai'.format(fasta=config['reads'])
    output:
        fasta='data/{coverage}x_longest.fasta',
        index='data/{coverage}x_longest.fasta.fai'
    conda: 'environment.yaml'
    shell:
        '''
        sort -k2nr {input.index} | \
            awk 'BEGIN {{sum = 0;}} {{sum += $2; print $1; if (sum >= {config[genomesize]} * {wildcards.coverage}) {{exit;}}}}' > \
            data/{wildcards.coverage}x_seqs.txt
        seqtk subseq {input.fasta} data/{wildcards.coverage}x_seqs.txt > {output.fasta}
        '''

rule index_fasta:
    input: '{basename}.fasta'
    output: '{basename}.fasta.fai'
    conda: 'environment.yaml'
    shell: 'samtools faidx {input}'

rule flye_assembly:
    input: 'data/{coverage}x_longest.fasta'
    output: directory('flye_output_{coverage}x')
    conda: 'environment.yaml'
    params:
        genome_size='20g'
    threads: 72
    shell:
        'flye --pacbio-raw {input} '
        '-g {params.genome_size} '
        '-o {output} -t {threads}'
