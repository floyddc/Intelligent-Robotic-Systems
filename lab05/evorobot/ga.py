import random
import math
import statistics
import os
import subprocess

GENOME_LENGTH = 50
POP_SIZE = 20
ELITE_SIZE = 5
GENERATIONS = 10
MUTATION_RATE = 0.1 # prob of mutating each gene
CX_RATE = 1 # prob of applying crossover
MUTATION_INTENSITY = 1 # stddev of a Gaussian distribution with mean 0
N_EVAL = 3

# Create random individual
def create_individual():
    return [random.uniform(-1,1) for _ in range(GENOME_LENGTH)]


# Compute fitness by evaluating the robot (N_EVAL times)
def fitness(individual):
    os.environ["GENOME"] = ",".join(map(str,individual))
    fvalue = []
    for _ in range(N_EVAL):
        proc = subprocess.Popen(
            ["argos3", "-c", "evaluate-controller-nn.argos"],
            stdout=subprocess.PIPE,
            text=True
        )
        for line in proc.stdout:
            if "FITNESS:" in line:
                fitness = str(line.strip().split(":")[1])
                fitness = float(fitness.replace(",", "."))
        fvalue.append(fitness)
    # fitness = statistics.mean(fvalue)
    fitness = min(fvalue)
    return fitness


# Selection: tournament
# Randomly pick 2 individuals and return the one with the highest fitness
def select_tournament(population, fitness_values, k=3):
    candidates = random.sample(range(len(population)), k)
    best = max(candidates, key=lambda i: fitness_values[i])
    return population[best]


# Selection: roulette wheel (proportional)
def select_proportional(population,fitness_values):
    total_fitness = sum(fitness_values)
    r = random.random() * total_fitness
    if r > total_fitness:
        r = total_fitness
    i = 0
    mysum = fitness_values[i]
    while mysum <= r:
        i += 1
        mysum += fitness_values[i]
    return population[i]


# Crossover: linear combination
def crossover(parent1, parent2):
    if random.random() <= CX_RATE:
        alpha = random.random()
        return [
            alpha * x + (1 - alpha) * y
            for x,y in zip(parent1,parent2)
        ]
    else:
        return parent1 if random.random() <= 0.5 else parent2


# Mutation: Gaussian noise
# each gene has a probability MUTATION_RATE to be changed
def mutate(individual):
    mutated = []
    for i in individual:
        if random.random() <= MUTATION_RATE:
            noise = random.gauss(0,MUTATION_INTENSITY)
            mutated.append(i + noise)
        else:     
            mutated.append(i)
    return mutated


def print_stats(pop,fv):
    idx = max(range(POP_SIZE), key=lambda i: fv[i])
    best = pop[idx]
    print("Gen", gen, ": Best fitness =", round(fv[idx],4))
    print("Best solution:", best)
    print("\n")

# Main GA loop

# 1. Initial population (POP_SIZE individuals)
population = [create_individual() for _ in range(POP_SIZE)]

# Replacement
for gen in range(GENERATIONS):
    # 2. Individuals evaluation -> fitness generation 
    fitness_values = [fitness(i) for i in population]
    new_population = []

    # Elitism
    if ELITE_SIZE > 0:
        elite_indices = sorted(range(POP_SIZE), key=lambda i: fitness_values[i], reverse=True)[:ELITE_SIZE]
        elite = [list(population[i]) for i in elite_indices]
    else:
        elite = []

    # Fill remaining slots with offspring
    for _ in range(POP_SIZE - len(elite)):
        # 3. Selection step
        parent1 = select_tournament(population, fitness_values)
        parent2 = select_tournament(population, fitness_values)
        # 4. Crossover
        child = crossover(parent1, parent2)
        # 5. Mutation
        child = mutate(child)
        # 6. New population 
        new_population.append(child)

    population = elite + new_population
    print_stats(population, fitness_values)
