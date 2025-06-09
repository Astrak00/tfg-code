import argparse
import sys
from pathlib import Path


def read_power_file(filepath, time_interval_ms=114):
    """
    Read power readings from file and calculate energy consumption
    
    Args:
        filepath: Path to file containing power readings (one per line)
        time_interval_ms: Time interval between readings in milliseconds
    
    Returns:
        tuple: (readings_list, total_energy_joules, individual_energies)
    """
    try:
        with open(filepath, 'r') as file:
            # Read all lines and convert to float, skip empty lines
            readings = []
            for line_num, line in enumerate(file, 1):
                line = line.strip()
                if line:  # Skip empty lines
                    try:
                        power_mw = float(line)
                        readings.append(power_mw)
                    except ValueError:
                        print(f"Warning: Invalid number on line {line_num}: '{line}'")
                        continue
        
        if not readings:
            raise ValueError("No valid readings found in file")
        
        # Calculate energy for each reading
        time_seconds = time_interval_ms / 1000
        individual_energies = []
        
        for power_mw in readings:
            energy_j = (power_mw / 1000) * time_seconds
            individual_energies.append(energy_j)
        
        total_energy = sum(individual_energies)
        
        return readings, total_energy, individual_energies
        
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {filepath}")
    except Exception as e:
        raise Exception(f"Error reading file: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="Convert milliwatt readings to joules"
    )
    parser.add_argument(
        "file", 
        help="Path to file containing power readings (mW, one per line)"
    )
    parser.add_argument(
        "-t", "--time-interval", 
        type=int, 
        default=114,
        help="Time interval between readings in milliseconds (default: 114)"
    )
    parser.add_argument(
        "-v", "--verbose", 
        action="store_true",
        help="Show individual energy calculations"
    )
    parser.add_argument(
        "-s", "--summary-only", 
        action="store_true",
        help="Show only summary statistics"
    )

    args = parser.parse_args()

    try:
        readings, total_energy, individual_energies = read_power_file(
            args.file, args.time_interval
        )

        if not args.summary_only:
            print(f"File: {args.file}")
            print(f"Time interval: {args.time_interval} ms")
            print(f"Number of readings: {len(readings)}")
            print("-" * 50)

        if args.verbose and not args.summary_only:
            print("Individual calculations:")
            for i, (power, energy) in enumerate(zip(readings, individual_energies)):
                print(f"Reading {i+1:3d}: {power:8.2f} mW → {energy:.6f} J")
            print("-" * 50)

        # Summary statistics
        avg_power = sum(readings) / len(readings)
        max_power = max(readings)
        min_power = min(readings)
        total_time = len(readings) * args.time_interval / 1000  # seconds

        if args.summary_only:
            print(f"{total_energy:.6f}")
        else:
            print(f"Power Statistics:")
            print(f"  Average: {avg_power:.2f} mW")
            print(f"  Maximum: {max_power:.2f} mW")
            print(f"  Minimum: {min_power:.2f} mW")
            print(f"")
            print(f"Energy Results:")
            print(f"  Total energy: {total_energy:.6f} J")
            print(f"  Total time: {total_time:.2f} s")
            print(f"  Average power: {total_energy/total_time*1000:.2f} mW")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()