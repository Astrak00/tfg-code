# Reading consumption from different machines

## MACOS - ARM

```bash
sudo powermetrics -i 200 --samplers cpu_power --hide-cpu-duty-cycle | grep "CPU Power:" | sudo tee -a output.file
```

The minimum interval is 25ms, where here it is set to 200 ms.
The output will be saved in `output.file` and will look like this:

```text
Machine model: Mac16,7
OS version: 24E263
Boot arguments:
Boot time: Wed May 14 23:27:40 2025

--multilpe lines--

CPU Power: 54 mW
GPU Power: 6 mW
ANE Power: 0 mW
Combined Power (CPU + GPU + ANE): 60 mW
```

from where we only need the power consumption of the CPU.

And we also need a way to insert a mark in the output file to know when we started and finished the test.
```bash
echo "=== WAYPOINT: $(date) ===" | sudo tee -a output.file
```

> [!info] We can not use `>>` as it does not work with the `>` of powermetrics.

## LINUX - Intel Xeon

```bash
perf stat -r 5 -e 'power/energy-pkg/, power/energy-ram/' <command>
```

The output will look like this:

```text
 Performance counter stats for '<command>' (5 runs):

       xxx,xxx,xxx.xxx power/energy-pkg/ (Joules)
       xxx,xxx,xxx.xxx power/energy-ram/ (Joules)

       0.123456789 seconds time elapsed
```

## LINUX - AMD Ryzen

## Raspberry Pi

```bash
sudo apt install powertop
sudo powertop
```

Alternative: 
[Medidor](https://www.amazon.com/-/es/Probador-potencia-Capacidad-teléfono-Amperímetro/dp/B0D529Z22P),
[Alternative](https://www.amazon.com/dp/B07DK6FT4Q/ref=sspa_dk_detail_4?pf_rd_p=7446a9d1-25fe-4460-b135-a60336bad2c9&pf_rd_r=GCD54TJ69S033P1END7K&pd_rd_wg=gtaqs&pd_rd_w=48fvx&content-id=amzn1.sym.7446a9d1-25fe-4460-b135-a60336bad2c9&pd_rd_r=1086cf9c-ea37-4276-9d5e-ef60acf0257e&s=industrial&sp_csd=d2lkZ2V0TmFtZT1zcF9kZXRhaWw&th=1)
