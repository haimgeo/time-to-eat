<html>
<head>
    <center><h1>TIME TO EAT</h1></center>
    <center><img  src="https://${bucket_id}.s3.us-east-1.amazonaws.com/veg.jpg" alt="top pic" /></center>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <title>Display JSON Data</title>
    <style>
        .json-container {
            font-family: Arial, sans-serif;
            padding: 20px;
        }
        .json-item {
            background-color: #f9f9f9;
            padding: 10px;
            margin: 10px 0;
            border-radius: 5px;
            box-shadow: 0 0 5px rgba(0, 0, 0, 0.1);
        }
        .json-item h3 {
            margin: 0;
        }
    </style>
</head>
<body>
    <h1>Describe Your Munch:</h1>
    <h2>Cuisine Style:</h2>
    <select name="cuisine-style" id="cuisine-style">
        <option value="">--Please choose an option--></option>

        <option value="italian">Italian</option>
        <option value="thai">Thai</option>
        <option value="mexican">Mexican</option>
        <option value="japanese">Japanese</option>
        <option value="mediterranean">Mediterranean</option>
        <option value="fusion cuisine">Fusion Cuisine</option>
        <!-- Add more options as needed -->
    </select>

    <h2>Vegetarian:</h2>
    <select name="vegetarian" id="vegan">
        <option value="">--Please choose an option--></option>

        <option value="True">True</option>
        <option value="False">False</option>
    </select>

    <h2>Gluten Free:</h2>
    <select name="gluten-free" id="gluten-free">
        <option value="">--Please choose an option--></option>

        <option value="True">True</option>
        <option value="False">False</option>
    </select>


    <h1></h1>
    <button onclick="submitRequest()">Submit</button>
    <div id="response"></div>

    <h2>restaurant Recommendation:</h2>
    <div class="json-container" id="jsonDisplay"></div>

    <script>
        function submitRequest() {
            const cuisine_style = document.getElementById('cuisine-style').value;
            const vegan = document.getElementById('vegan').value;
            const gluten_free = document.getElementById('gluten-free').value;
            const timestamp = new Date();

           console.log(cuisine_style, vegan, gluten_free, timestamp)
            
            
            response = axios.post("${function_url}", {
                headers: {
                    "Content-Type": "application/json",
                },
                cuisine_style: cuisine_style,
                vegetarian: vegan,
                gluten_free: gluten_free,
                timestamp: timestamp
            })
            .then(function (response) {
                document.getElementById('response').innerHTML = JSON.stringify(response.data);
            })
            .catch(function (error) {
                console.log(error);
            });
        }

        // Function to display JSON data
        function displayJSONData(data) {
            const container = document.getElementById('jsonDisplay');
                container.appendChild(data);
            // });
        }

        // Call the function to display the JSON data
        displayJSONData(response);
    </script>
</body>
</html>
