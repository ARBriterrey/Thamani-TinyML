def bin_to_csv(bin_path, raw_bytes):
    csv_path = os.path.splitext(bin_path)[0] + '.csv'
    n_frames = len(raw_bytes) // FRAME_SIZE
    leftover = len(raw_bytes) % FRAME_SIZE

    if leftover:
        print(f"  {yellow('WARNING')}: {leftover} trailing bytes ignored")

    print(f"  Converting {n_frames:,} frames to CSV ...", flush=True)

    with open(csv_path, 'w', newline='') as fh:
        writer = csv.DictWriter(fh, fieldnames=CSV_FIELDS)
        writer.writeheader()
        for i in range(n_frames):
            pres, ch1, ch2 = struct.unpack_from(FRAME_FMT, raw_bytes,
                                                 i * FRAME_SIZE)
            writer.writerow({
                'pressure_mmhg': pres,
                'ch1_raw':       ch1,
                'ch2_raw':       ch2,
            })

    # Quick statistics
    pres_vals = [struct.unpack_from(FRAME_FMT, raw_bytes, i * FRAME_SIZE)[0]
                 for i in range(n_frames)]
    ch1_vals  = [struct.unpack_from(FRAME_FMT, raw_bytes, i * FRAME_SIZE)[1]
                 for i in range(n_frames)]
    ch2_vals  = [struct.unpack_from(FRAME_FMT, raw_bytes, i * FRAME_SIZE)[2]
                 for i in range(n_frames)]

    print(f"  {green('Saved CSV')}: {csv_path}")
    print()
    print(f"  ── Recording summary ────────────────────────────────────────")
    print(f"     Frames      : {n_frames:,}")
    print(f"     Duration    : {n_frames / 500:.2f} s  (at  500Hz)")
    if pres_vals:
        avg_p = sum(pres_vals) / len(pres_vals)
        print(f"     Pressure    : min={min(pres_vals)}  "
              f"max={max(pres_vals)}  avg={avg_p:.1f}  mmHg")
    if ch1_vals:
        print(f"     CH1 raw     : min={min(ch1_vals)}  max={max(ch1_vals)}")
    if ch2_vals:
        print(f"     CH2 raw     : min={min(ch2_vals)}  max={max(ch2_vals)}")
    print(f"  ─────────────────────────────────────────────────────────────")
    print()
    return csv_path