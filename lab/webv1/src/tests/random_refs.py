import uuid

def random_suffix():
    return uuid.uuid4().hex[:6]

def random_sku(name=""):
    return f"sku-{name}--{random_suffix()}"

def random_transcript_ref(name=""):
    return f"transcript-{name}--{random_suffix()}"

def random_predictionid(name=""):
    return f"prediction-{name}--{random_suffix()}"