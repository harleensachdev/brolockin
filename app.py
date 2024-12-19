from flask import Flask, request, jsonify
import openai
import os

app = Flask(__name__)

# Fetch the OpenAI API key from an environment variable
openai.api_key = os.getenv("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")

@app.route('/api/feedback', methods=['POST'])
def generate_feedback():
    try:
        # Get input data from the request
        data = request.json
        extracted_texts = data.get('extracted_texts', [])
        percentage_score = data.get('percentage_score', "N/A")
        target_score = data.get('target_score', "N/A")
        
        # Combine extracted texts into a single string
        combined_text = "\n".join(extracted_texts)

        # Define the messages for ChatCompletion
        messages = [
            {"role": "system", "content": "You are an AI tutor providing feedback to a student on their test."},
            {"role": "user", "content": f"""
            The student scored {percentage_score}%, with a target score of {target_score}%.
            
            Here are the extracted answers from the test:
            {combined_text}

            Provide detailed, constructive feedback, including:
            1. Areas of improvement.
            2. Mistakes found in their answers.
            3. Specific tips to achieve their target score.
            4. Motivational encouragement.
            """}
        ]

        # Generate feedback using OpenAI's ChatCompletion API
        response = openai.ChatCompletion.create(
            model="gpt-4o-mini",  # Replace with "gpt-3.5-turbo" if needed
            messages=messages,
            max_tokens=500,
            temperature=0.7
        )

        # Extract the AI-generated feedback
        feedback = response.get('choices', [{}])[0].get('message', {}).get('content', '').strip()

        return jsonify({"feedback": feedback})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
