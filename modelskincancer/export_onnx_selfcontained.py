import json
import sys
from pathlib import Path

import torch
import torch.nn as nn
import torchvision

BASE = Path(__file__).resolve().parent
OUT_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else BASE / "selfcontained_onnx"
OUT_DIR.mkdir(parents=True, exist_ok=True)

CHECKPOINTS = [
    "baseline_best",
    "smartphone_augmented_best",
]
NUM_CLASSES = 7
INPUT_SIZE = 224
OPSET = 18


def build_model(num_classes):
    model = torchvision.models.efficientnet_b0(weights=None)
    in_feats = model.classifier[-1].in_features
    model.classifier[-1] = nn.Linear(in_feats, num_classes)
    return model


for name in CHECKPOINTS:
    ckpt_path = BASE / f"{name}.pth"
    ckpt = torch.load(ckpt_path, map_location="cpu", weights_only=True)
    model_state = ckpt["model_state_dict"]
    assert ckpt["model_name"] == "efficientnet_b0"
    assert ckpt["image_size"] == INPUT_SIZE
    assert list(ckpt["class_names"]) == [
        "akiec", "bcc", "bkl", "df", "mel", "nv", "vasc",
    ]

    model = build_model(NUM_CLASSES)
    model.load_state_dict(model_state)
    model.eval()

    dummy_input = torch.randn(1, 3, INPUT_SIZE, INPUT_SIZE)

    with torch.no_grad():
        pytorch_output = model(dummy_input)
    assert pytorch_output.shape == (1, NUM_CLASSES)

    out_name = "baseline_best_mobile.onnx" if name == "baseline_best" else "smartphone_augmented_mobile.onnx"
    out_path = OUT_DIR / out_name

    torch.onnx.export(
        model,
        dummy_input,
        str(out_path),
        export_params=True,
        opset_version=OPSET,
        do_constant_folding=True,
        dynamo=False,
        input_names=["input"],
        output_names=["logits"],
        dynamic_axes={
            "input": {0: "batch_size"},
            "logits": {0: "batch_size"},
        },
    )

    import onnx

    onnx_model = onnx.load(str(out_path))
    onnx.save_model(onnx_model, str(out_path), save_as_external_data=False)

    import onnxruntime as ort
    import numpy as np

    sess = ort.InferenceSession(str(out_path), providers=["CPUExecutionProvider"])
    onnx_output = sess.run(["logits"], {"input": dummy_input.numpy()})[0]
    assert onnx_output.shape == (1, NUM_CLASSES)

    diff = float(np.max(np.abs(pytorch_output.detach().numpy() - onnx_output)))
    print(f"{out_name}: size={out_path.stat().st_size / 1024 / 1024:.2f} MB, "
          f"input={sess.get_inputs()[0].shape}, output={sess.get_outputs()[0].shape}, "
          f"max diff={diff:.2e}")

print("DONE")
