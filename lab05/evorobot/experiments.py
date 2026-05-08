import random
import statistics
import os
import subprocess
import csv

# ── shared GA primitives ──────────────────────────────────────────────────────

GENOME_LENGTH = 50

def create_individual():
    return [random.uniform(-1, 1) for _ in range(GENOME_LENGTH)]

def evaluate_once():
    proc = subprocess.Popen(
        ["argos3", "-c", "evaluate-controller-nn.argos"],
        stdout=subprocess.PIPE, text=True
    )
    f = 0.0
    for line in proc.stdout:
        if "FITNESS:" in line:
            f = float(line.strip().split(":")[1].replace(",", "."))
    return f

def fitness(individual, n_eval=3, use_min=True):
    os.environ["GENOME"] = ",".join(map(str, individual))
    fvalues = [evaluate_once() for _ in range(n_eval)]
    return min(fvalues) if use_min else statistics.mean(fvalues)

def mutate(individual, mutation_rate=0.1, mutation_intensity=1.0):
    ind = list(individual)
    for i in range(len(ind)):
        if random.random() <= mutation_rate:
            ind[i] += random.gauss(0, mutation_intensity)
            ind[i] = max(-1.0, min(1.0, ind[i]))
    return ind

def crossover(p1, p2, cx_rate=1.0):
    if random.random() <= cx_rate:
        a = random.random()
        return [a * x + (1 - a) * y for x, y in zip(p1, p2)]
    return list(p1) if random.random() <= 0.5 else list(p2)

def select_proportional(population, fv):
    total = sum(fv)
    r = random.random() * total
    s, i = 0, 0
    while s <= r and i < len(population) - 1:
        s += fv[i]; i += 1
    return population[i - 1]

def select_tournament(population, fv, k=2):
    candidates = random.sample(range(len(population)), k)
    best = max(candidates, key=lambda i: fv[i])
    return population[best]

# ── generic GA runner ─────────────────────────────────────────────────────────

def run_ga(pop_size, generations, elite_size, mutation_rate, cx_rate,
           mutation_intensity, n_eval, selection="tournament", use_min=True):
    """Returns list of best-fitness-per-generation."""
    population = [create_individual() for _ in range(pop_size)]
    best_per_gen = []

    for _ in range(generations):
        fv = [fitness(ind, n_eval, use_min) for ind in population]
        best_per_gen.append(max(fv))

        # Elitism
        elite = []
        if elite_size > 0:
            top_idx = sorted(range(pop_size), key=lambda i: fv[i], reverse=True)[:elite_size]
            elite = [list(population[i]) for i in top_idx]

        offspring = []
        for _ in range(pop_size - len(elite)):
            if selection == "tournament":
                p1 = select_tournament(population, fv)
                p2 = select_tournament(population, fv)
            else:
                p1 = select_proportional(population, fv)
                p2 = select_proportional(population, fv)
            child = crossover(p1, p2, cx_rate)
            child = mutate(child, mutation_rate, mutation_intensity)
            offspring.append(child)

        population = elite + offspring

    return best_per_gen


# ── experiment helpers ────────────────────────────────────────────────────────

def replicate(n_replicas, label, **kwargs):
    results = []
    for rep in range(n_replicas):
        print(f"  [{label}] replica {rep+1}/{n_replicas}...")
        bpg = run_ga(**kwargs)
        results.append(bpg[-1])  # best fitness at last generation
    med = statistics.median(results)
    mn  = statistics.mean(results)
    print(f"  → {label}: median={med:.4f}  mean={mn:.4f}  values={[round(r,4) for r in results]}")
    return label, med, mn, results


# ── Task 7: CX_RATE ∈ {0, 0.5, 1}, 5 replicas ───────────────────────────────

def task7():
    print("\n=== TASK 7: CX_RATE comparison (5 replicas each) ===")
    base = dict(pop_size=10, generations=5, elite_size=0,
                mutation_rate=0.1, mutation_intensity=1.0,
                n_eval=3, selection="proportional", use_min=True)
    rows = []
    for cx in [0, 0.5, 1.0]:
        label = f"CX={cx}"
        row = replicate(5, label, cx_rate=cx, **base)
        rows.append(row)
    return rows

# ── Task 9: replacement vs elitism, CX_RATE=0, 5 replicas ───────────────────

def task9():
    print("\n=== TASK 9: Replacement vs Elitism (CX_RATE=0, 5 replicas each) ===")
    base = dict(pop_size=10, generations=5,
                mutation_rate=0.1, cx_rate=0.0,
                mutation_intensity=1.0, n_eval=3,
                selection="tournament", use_min=True)
    rows = []
    row = replicate(5, "No elitism (elite=0)", elite_size=0, **base)
    rows.append(row)
    row = replicate(5, "Elitism (elite=5)",    elite_size=5, **base)
    rows.append(row)
    return rows

# ── Task 11: tournament vs roulette wheel, 5 replicas ────────────────────────

def task11():
    print("\n=== TASK 11: Tournament vs Roulette wheel (5 replicas each) ===")
    base = dict(pop_size=10, generations=5, elite_size=5,
                mutation_rate=0.1, cx_rate=0.0,
                mutation_intensity=1.0, n_eval=3, use_min=True)
    rows = []
    row = replicate(5, "Tournament",   selection="tournament",    **base)
    rows.append(row)
    row = replicate(5, "Proportional", selection="proportional",  **base)
    rows.append(row)
    return rows

# ── main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    all_rows = []
    all_rows += task7()
    all_rows += task9()
    all_rows += task11()

    with open("results.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["experiment", "median", "mean", "values"])
        for label, med, mn, vals in all_rows:
            writer.writerow([label, round(med, 4), round(mn, 4), vals])

    print("\n=== SUMMARY ===")
    print(f"{'Experiment':<35} {'Median':>8} {'Mean':>8}")
    print("-" * 55)
    for label, med, mn, _ in all_rows:
        print(f"{label:<35} {med:>8.4f} {mn:>8.4f}")

    print("\nDetailed results saved to results.csv")
