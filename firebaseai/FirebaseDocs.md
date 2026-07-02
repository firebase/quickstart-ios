### Guiding Principles

* **Prioritize a continuous narrative:** Keep the developer in the flow of the code rather than forcing them to jump to external documentation for core configuration steps. ([thread](https://docs.google.com/document/d/1zBitr-qR9cqG0tt1c8AYFrafMM2FcGkJvFVCv2D_SDs/edit?disco=AAAB7xVQlE0))  
* **Balance "Self-contained" vs. "Linked":** Provide the "essential" steps (the specific Fuji-related tweaks) directly in the guide to avoid fragmentation.  
* **Contextual linking:** Link to authoritative documentation only the first time a feature (e.g., Firebase App Check, AI Logic) is mentioned. Subsequent mentions should focus on the implementation flow.  
* **Code transparency:** Code snippets must reflect incremental progress that is in sync with configuration steps (e.g., create app on console, then configure Firebase in app).  
* **Compile-ready:** The app should be in a state that compiles and runs at each major step.  
* **Minimize context switching:** Avoid forcing unnecessary transitions between Xcode and the Firebase console.

### TODOs

* Identify where caveats should be added for readers extending an existing app.

### Outline 

To view the current outline, select the overflow menu (three dots) on the current document tab and select *Show Outline*.  
![][image1]

### Key Decisions

* **DevSite Location:** Put it under [https://firebase.google.com/docs/ai-logic/**solutions**/overview](https://firebase.google.com/docs/ai-logic/solutions/overview)   
* **Title:** [See resolved thread](https://docs.google.com/document/d/1zBitr-qR9cqG0tt1c8AYFrafMM2FcGkJvFVCv2D_SDs/edit?disco=AAAB83hTjGU).  
  * Refer to the feature like “this integration”  
* **Branch Name:** `wwdc26-preview`  
  * Thread for if we run into issues with the branch not updating for clients ([thread](https://docs.google.com/document/d/1zBitr-qR9cqG0tt1c8AYFrafMM2FcGkJvFVCv2D_SDs/edit?disco=AAAB83oWffw)).

---

**BEGIN PUBLIC CONTENT**

# **\[page\] Get started: Access the Gemini API through Apple's Foundation Models framework**

**Preview**: Accessing the Gemini API through Apple's Foundation Models framework is currently in public preview, which means that it isn't subject to any SLA or deprecation policy and could change in backwards-incompatible ways.  
Also, this integration relies on beta APIs, so apps using it cannot be submitted to the App Store until the next Xcode version reaches General Availability (GA) and supports production submissions.

\<add intro here\> \<insert link to video here\>

This guide shows you how to get started using the Firebase AI Logic integration to access the Gemini API through Apple's Foundation Models framework.

To protect access to Gemini models, this guide also shows you how to set up \[Firebase App Check\]([https://firebase.google.com/docs/app-check](https://firebase.google.com/docs/app-check)), which is ***critical*** even during development.

## Prerequisites

* Install the latest \[Xcode 27 beta\]([https://developer.apple.com/download/all/?q=Xcode](https://developer.apple.com/download/all/?q=Xcode)).  
* An Apple platform simulator or a physical device, both running the corresponding beta OS version (for example, iOS 27 beta).  
* A new Xcode project of an Apple platforms app using a **SwiftUI interface**.

### Supported Gemini models

The integration with Apple’s Foundation Models framework supports the following Gemini models.

* General purpose models  
  * `gemini-3.1-pro-preview`  
  * `gemini-3.5-flash`  
  * `gemini-3.1-flash-lite`  
* Image-generating models  
  * `gemini-3-pro-image-preview` (aka "Nano Banana Pro")  
  * `gemini-3.1-flash-image-preview` (aka "Nano Banana 2")  
  * `gemini-2.5-flash-image` (aka "Nano Banana")

Gemini Live API models and Imagen models are ***not*** supported. Note that Gemini 2.5 models are technically supported, but they're not recommended for new projects and require special configuration not covered in these guides.

## Step 1: Create a Firebase project

We recommend starting with a new Firebase project to explore this integration.

1. Sign into the \[Firebase console\]([https://console.firebase.google.com/](https://console.firebase.google.com/)).  
2. Click **Create a new Firebase project**.  
3. Follow the on-screen instructions. You do **not** need to enable Google Analytics.

## Step 2: Connect your app to Firebase

To connect your app to Firebase, you must register it with your Firebase project and add a configuration file to your codebase.

1. In the center of the \[project overview\]([https://console.firebase.google.com/project/\_/overview](https://console.firebase.google.com/project/_/overview)) page, click the **iOS+** icon to launch the setup workflow.  
2. Register your app:  
   1. Enter your app's **bundle ID**. Make sure it matches the bundle ID of the project you're building in Xcode.  
   2. Click **Register app**.  
3. Add the Firebase configuration file.  
   This file contains the settings for the Firebase SDK to connect to your Firebase project.  
   1. Click **Download GoogleService-Info.plist** to get your configuration file.  
   2. Move `GoogleService-Info.plist` into the root of your Xcode project and add it to all targets.  
   3. Click **Next** in the Firebase console.  
4. The workflow in the console provides *generic* instructions for adding the Firebase SDK to your app, so skip ahead to the next step in this guide for specific instructions for Firebase AI Logic.

## Step 3: Add the Firebase libraries and initialize Firebase in your app

1. Use Swift Package Manager to add the Firebase AI Logic library:  
   1. In Xcode, with your app project open, select **File** \> **Add Packages**.  
   2. Enter the Firebase Apple SDK repository URL:

```
https://github.com/firebase/firebase-ios-sdk
```

   3. Select the Dependency Rule as **Branch** and enter **`wwdc26-preview`**.  
   4. Click **Add Package**. Xcode will resolve and download the dependencies.  
   5. When prompted, add the **`FirebaseAILogic`** library to your app target.  
2. Initialize Firebase when your app starts up by adding the following code to your app's main entry point:

```swift
import SwiftUI
import FirebaseCore

@main
struct YourApp: App {  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
```

## Step 4: Enable and secure Firebase services

Now that your app is configured to use Firebase, you need to enable the Firebase AI Logic service and protect access to its associated APIs using Firebase App Check.

### Set up **Firebase AI Logic** in your Firebase project

1. In the Firebase console, go to **AI Services** \> [**AI Logic**](https://console.firebase.google.com/project/_/ailogic/?useAutoProject=true).  
2. Click **Get started** to launch the setup workflow.  
3. We recommend choosing the **Gemini Developer API** provider to get started quickly at no cost.

### Set up **Firebase App Check** in your Firebase project

**Using Firebase App Check to protect the APIs associated with Firebase AI Logic is *critical*.** When enforced, Firebase App Check only allows incoming requests that are from your actual app and an untampered device. Firebase App Check supports many attestation providers, including Apple's \[App Attest\]([https://developer.apple.com/documentation/devicecheck](https://developer.apple.com/documentation/devicecheck)).

The following steps are for a baseline, default setup for App Check. Learn more about [additional configuration options for App Check](https://firebase.google.com/docs/ai-logic/app-check) (like adjusting the TTL of tokens and enabling limited-use tokens).

\[\!TIP\] **Developing a Mac app?** If you're developing a macOS app, skip the below steps and use the \[DeviceCheck provider\]([https://firebase.google.com/docs/app-check/ios/devicecheck-provider](https://firebase.google.com/docs/app-check/ios/devicecheck-provider)) instead of App Attest, which is unsupported on macOS. 

Here's how to register the App Attest provider in the Firebase console:

1. In the Firebase console, go to **Security** \> \[**App Check\](**[https://console.firebase.google.com/project/\_/appcheck/](https://console.firebase.google.com/project/_/appcheck/)**)**.  
2. Click **Get started**.  
3. In the **\[Apps** tab**\](**[https://console.firebase.google.com/project/\_/appcheck/apps/](https://console.firebase.google.com/project/_/appcheck/apps/)**)**, register your app to use App Check with the \[**App Attest** provider\]([https://firebase.google.com/docs/app-check/ios/app-attest-provider](https://firebase.google.com/docs/app-check/ios/app-attest-provider)).   
4. In the \[**APIs** tab\]([https://console.firebase.google.com/project/\_/appcheck/products/](https://console.firebase.google.com/project/_/appcheck/products/)), select **Firebase AI Logic**, and click **Enforce**.

**(+) Before distributing your app, configure the App Attest capability**

**Note:** If you’re going to start with the App Check debug provider (next section), these steps aren't required until you distribute your app. For now, you can skip ahead to the next section.

1. In Xcode, add the \[App Attest capability\]([https://developer.apple.com/documentation/xcode/adding-capabilities-to-your-app](https://developer.apple.com/documentation/xcode/adding-capabilities-to-your-app)) to your app.  
2. In your Xcode project's `.entitlements` file, set the \[App Attest environment\]([https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.devicecheck.appattest-environment](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.devicecheck.appattest-environment)) to `production`.

### Configure the App Check Debug Provider for local development

For local development, configure the \[App Check Debug Provider\]([https://firebase.google.com/docs/app-check/ios/debug-provider](https://firebase.google.com/docs/app-check/ios/debug-provider)). Setting up this provider bypasses attestation during development so you can verify your app's logic without modifying the production security configuration you set up above.

1. In your Xcode project, import `FirebaseAppCheck` and initialize App Check with the debug provider factory before you configure `FirebaseApp`.

```swift
import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct YourApp: App {
  init() {
    let providerFactory = AppCheckDebugProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}

```

2. Obtain your debug token:  
   1. Launch your app in the simulator or on your test device.  
   2. Open the Xcode console and look for the App Check debug token. Because it is generated at app startup, it should be one of the first few logs you see. It will look similar to this:

      \<pre\>\&lt;Warning\&gt; \[AppCheckCore\]\[I-GAC004001\] App Check debug token: '123a4567-b89c-12d3-e456-789012345678'.\</pre\>

1. Copy the token (for example, `123a4567-b89c-12d3-e456-789012345678`).

3. Provide your debug token to App Check within the Firebase console:  
   1. In the Firebase console, navigate to **Security** \> **App Check** \> [**Apps**](https://console.firebase.google.com/project/_/appcheck/apps/).  
   2. Find your app, click the overflow menu (three dots), and select **Manage debug tokens**.  
   3. Click **Add debug token**, enter a name (for example, `My Simulator`), paste the token, and click **Save**.

For details about the debug provider (including how to get a new debug token), check out the [official App Check docs](https://firebase.google.com/docs/app-check/ios/debug-provider).

\[\!WARNING\] **Keep your debug token private.** Because this debug token lets anyone access your Firebase AI Logic resources without a valid device, you must keep it private. Do not commit it to a public repository. If a registered token is ever compromised, revoke it immediately in the Firebase console.

## Step 5: Initialize the AI Logic service in your app

With Firebase and App Check configured, you can now initialize the Firebase AI Logic service in your app.

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")
```

## Step 6: Send a request to a Gemini model

With Firebase AI Logic setup, protected, and initialized in your app, you're ready to send a request to a Gemini model.

The following example shows the most basic type of request – generating text from a text-only prompt:

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

// Inject the model into Apple's LanguageModelSession.
let session = LanguageModelSession(model: model)

// Use the session to generate a text response to a prompt.
let response = try await session.respond(to: "Write a story about a magic backpack.")
print(response.content)
```

Gemini models also support other types of requests, like [analyzing images and PDFs](#generate-text-from-multimodal-input-\(like-images\)), [generating structured JSON output](#generate-structured-output-\(like-json\)), and [generating and editing images](#generate-and-edit-images-\(using-"nano-banana"-models\)) (using "Nano Banana" models). See examples for these types of requests in the [docs](#[page]-available-capabilities-when-accessing-the-gemini-api-through-apple's-foundation-models-framework) or in the sample app.

### Stream the response

You can achieve faster interactions by not waiting for the entire result from the model generation, and instead use *streaming* to handle partial results. To stream the response, use `streamResponse(to:)` instead of `respond(to:)`.

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

// Inject the model into Apple's LanguageModelSession.
let session = LanguageModelSession(model: model)

// Use the session to generate a streamed text response to a prompt.
let response = try await session.streamResponse(to: "Write a story about a magic backpack.")
print(response.content)
```

## Next steps

* Check out the sample app or a video to see this integration in a real-world app.  
* Explore the [available capabilities](#[page]-available-capabilities-when-accessing-the-gemini-api-through-apple's-foundation-models-framework) when accessing the Gemini API through Apple's Foundation Models framework.  
* Learn how to [configure the model](#[page]-configuration-options-when-accessing-the-gemini-api-through-apple's-foundation-models-framework) to control its responses, including setting a thinking level.  
* Learn how to [provide tools to the model](#[page]-provide-tools-to-the-model-when-accessing-the-gemini-api-through-apple's-foundation-models-framework), including grounding for up-to-date information.  
* Read more about \[Firebase App Check\]([https://firebase.google.com/docs/ai-logic/app-check](https://firebase.google.com/docs/ai-logic/app-check)) and how it protects your resources.

# **\[page\] Available capabilities when accessing the Gemini API through Apple's Foundation Models framework** {#[page]-available-capabilities-when-accessing-the-gemini-api-through-apple's-foundation-models-framework}

**Preview**: Accessing the Gemini API through Apple's Foundation Models framework is currently in public preview, which means that it isn't subject to any SLA or deprecation policy and could change in backwards-incompatible ways.  
Also, this integration relies on beta APIs, so apps using it cannot be submitted to the App Store until the next Xcode version reaches General Availability (GA) and supports production submissions.

This guide shows you how to send various types of requests to the Gemini API through Apple's Foundation Models framework using the Firebase AI Logic SDK for Apple platforms.

The examples on this page assume that you've completed the [Get started: Access the Gemini API through Apple's Foundation Models framework](https://firebase.devsite.corp.google.com/docs/ai-logic/apple-foundation-models-framework/get-started).

This page shows examples for how to send the following types of requests:

* [Generate text from text-only input](#generate-text-from-text-only-input)  
* Generate text from a multi-turn session (chat)  
* [Generate text from multimodal input (like images)](#generate-text-from-multimodal-input-\(like-images\))  
* [Generate and edit images](#generate-and-edit-images-\(using-"nano-banana"-models\)) (using "Nano Banana" models)  
* [Generate structured output (like JSON)](#generate-structured-output-\(like-json\))

## Generate text

Gemini supports the following capabilities for generating text:

* [Generate text from text-only input](#generate-text-from-text-only-input)  
* Generate text from a multi-turn session (chat)  
* [Generate text from multimodal input (like images)](#generate-text-from-multimodal-input-\(like-images\))

#### Models that support this capability

* `gemini-3.1-pro-preview`  
* `gemini-3.5-flash`  
* `gemini-3.1-flash-lite`

### Generate text from text-only input {#generate-text-from-text-only-input}

You can ask a Gemini model to generate text by prompting with text-only input.

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

// Provide a prompt that contains text.
let prompt = "Write a story about a magic backpack."

// For a single-turn interaction, create a new session each time you call the model.
let session = LanguageModelSession(model: model)

// Generate a text response to the prompt.
let response = try await session.respond(to: prompt)
print(response.content)
```

**(+) Stream the response**  
You can achieve faster interactions by not waiting for the entire result from the model generation, and instead use *streaming* to handle partial results. To stream the response, use `streamResponse(to:)` instead of `respond(to:)`.

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

// Provide a prompt that contains text.
let prompt = "Write a story about a magic backpack."

// For a single-turn interaction, create a new session each time you call the model.
let session = LanguageModelSession(model: model)

// Generate a text response to the prompt.
// To stream the response, use `streamResponse(to:)` instead of `respond(to:)`
let response = try await session.streamResponserespond(to: prompt)
print(response.content)
```

### Generate text from a multi-turn session

```
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

// Optionally specify previous session interactions.
let transcript = Transcript(entries: [
  .prompt(.init(segments: [.text(.init(content: "Hello, I have 2 dogs in my house."))])),
  .response(.init(
    assetIDs: [],
    segments: [.text(.init(content: "Great to meet you. What would you like to know?"))]
  ))
])

// Create a session, optionally rehydrating from a transcript.
let session = LanguageModelSession(model: model, transcript: transcript)

// Generate a text response to the prompt.
let response = try await session.respond(to: "How many paws are in my house?")
print(response.content)
```

**(+) Stream the response**  
You can achieve faster interactions by not waiting for the entire result from the model generation, and instead use *streaming* to handle partial results. To stream the response, use `streamResponse(to:)` instead of `respond(to:)`.

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

TODO
```

### Generate text from multimodal input (like images) {#generate-text-from-multimodal-input-(like-images)}

**Note**: In the current release for this integration, multimodal media input can be images or documents (like PDFs). Video and audio input are not yet supported. 

You can ask a Gemini model to generate text by prompting with text and a file—providing each input file's `mimeType` and the file itself. Find [requirements and recommendations for input files](https://firebase.devsite.corp.google.com/docs/ai-logic/generate-text?db=rachelsaunders&api=dev#requirements-recommendations-for-input) later on this page.

The following example shows the basics of how to generate text from a file input by analyzing a single image file provided as inline data (base64-encoded file).

Note that this example shows providing the file inline, but the SDKs also support [providing a file using a browser/HTTP URL](https://firebase.devsite.corp.google.com/docs/ai-logic/input-file-requirements?db=rachelsaunders).

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

TODO
```

**(+) Stream the response**  
You can achieve faster interactions by not waiting for the entire result from the model generation, and instead use *streaming* to handle partial results. To stream the response, use `streamResponse(to:)` instead of `respond(to:)`.

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

TODO
```

## Generate and edit images (using "Nano Banana" models) {#generate-and-edit-images-(using-"nano-banana"-models)}

Gemini supports the following capabilities for generating and editing images:

* [Generate an image from text-only input](#generate-an-image-from-text-only-input)  
* [Edit an image](#edit-an-image)  
* [Iterate and edit images using multi-turn chat](#iterate-and-edit-images-using-multi-turn-chat)

**Note**: Image-generating models let you optionally provide an [\`imageConfig\`](#configure-image-output) to specify aspect ratios and image sizes.

#### Models that support this capability

* `gemini-3-pro-image-preview` (aka "Nano Banana Pro")  
* `gemini-3.1-flash-image-preview` (aka "Nano Banana 2")  
* `gemini-2.5-flash-image` (aka "Nano Banana")

### Generate an image from text-only input {#generate-an-image-from-text-only-input}

You can ask a Gemini model to generate images by prompting with text.

Include response modalities of `TEXT` and `IMAGE` in your model configuration (or exclude `TEXT` if you only want image output).

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini image-generating model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.1-flash-image-preview")

TODO
```

### Edit an image {#edit-an-image}

You can ask a Gemini model to edit images by prompting with text and one or more images.

Include response modalities of `TEXT` and `IMAGE` in your model configuration (or exclude `TEXT` if you only want image output).

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini image-generating model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.1-flash-image-preview")

TODO
```

### Iterate and edit images using multi-turn chat {#iterate-and-edit-images-using-multi-turn-chat}

Using multi-turn chat, you can iterate with a Gemini model on the images that it generates or that you supply.

Include response modalities of `TEXT` and `IMAGE` in your model configuration (or exclude `TEXT` if you only want image output), and call `startChat()` and `sendMessage()` to send new user messages.

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini image-generating model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.1-flash-image-preview")

TODO
```

## Generate structured output (like JSON) {#generate-structured-output-(like-json)}

#### Models that support this capability

* `gemini-3.1-pro-preview`  
* `gemini-3.5-flash`  
* `gemini-3.1-flash-lite`

```swift
import SwiftUI
import FirebaseCore
import FirebaseAILogic

// Initialize the Vertex AI Gemini API backend service.
// Specify `global` as the location to access the Gemini model.
let ai = model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
// Initialize a `geminiLanguageModel` with a Gemini model that supports your use case.
let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")

TODO
```

# **\[page\] Configuration options when accessing the Gemini API through Apple's Foundation Models framework** {#[page]-configuration-options-when-accessing-the-gemini-api-through-apple's-foundation-models-framework}

**Preview**: Accessing the Gemini API through Apple's Foundation Models framework is currently in public preview, which means that it isn't subject to any SLA or deprecation policy and could change in backwards-incompatible ways.  
Also, this integration relies on beta APIs, so apps using it cannot be submitted to the App Store until the next Xcode version reaches General Availability (GA) and supports production submissions.

The examples on this page assume that you've completed the [Get started: Access the Gemini API through Apple's Foundation Models framework](https://firebase.devsite.corp.google.com/docs/ai-logic/apple-foundation-models-framework/get-started).

In each request to a model, you can send along a model configuration to control how the model generates a response. Each model offers different configuration options.

The configuration is maintained for the lifetime of the session. If you want to use a different config, create a new session with that config.

## System instructions

*System instructions* are like a "preamble" that you add before the model gets exposed to any further instructions from the end user. It lets you steer the behavior of the model based on your specific needs and use cases.

```swift
import FoundationModels
import FirebaseCore
import FirebaseAILogic

let model = FirebaseAI.firebaseAI().geminiLanguageModel(name: "GEMINI_MODEL_NAME")

// Specify the system instructions as part of creating the LanguageModelSession
let session = LanguageModelSession(
    model: model,
    instructions: "You are a cat. Your name is Neko."
)

// ...
```

## Configure thinking (aka "reasoning")

The following is a high-level description of how to configure the amount of *thinking* that a Gemini model can do. Note that Apple calls the thinking capability *reasoning*. For details, best practices, and use cases for thinking, see [Thinking](https://firebase.google.com/docs/ai-logic/thinking) in the general AI Logic docs.

Note the following:

* Gemini 3.x models always use thinking; you ***cannot*** disable or turn off thinking for these models.  
* Gemini 3.x models always use *dynamic thinking* – the model decides when and how much it thinks up to the configured amount.

### Set the thinking level

```swift
TODO
```

### Supported thinking level values

The following table lists the thinking level values that you can set for each model by configuring the model's `thinkingLevel`.

\< within DevSite share the table from the thinking page \>

## Configure image output {#configure-image-output}

When using image-generating Gemini models (like "Nano Banana" models), you can set an \`imageConfig\`.

```swift
TODO
```

\< within DevSite share the supported values from the nano banana page \>

## General configuration

Gemini models support some more general configuration parameters, as described in the table later in this section. Note that for Gemini 3.x models, configuring temperature, topK, and topP is not recommended.

```swift
TODO
```

| Parameter | Description | Default value |
| :---- | :---- | :---- |
| Candidate count `candidateCount` | Specifies the number of response variations to return. For each request, you're charged for the output tokens of all candidates, but you're only charged once for the input tokens. Supported values: `1` \- `8` (inclusive) | `1` |
| Frequency penalty `frequencyPenalty` | Controls the probability of including tokens that repeatedly appear in the generated response. Positive values penalize tokens that repeatedly appear in the generated content, decreasing the probability of repeating content. | \--- |
| Max output tokens `maxOutputTokens` | Specifies the maximum number of tokens that can be generated in the response. | \--- |
| Presence penalty `presencePenalty` | Controls the probability of including tokens that already appear in the generated response. Positive values penalize tokens that already appear in the generated content, increasing the probability of generating more diverse content. | \--- |
| Stop sequences `stopSequences` | Specifies a list of strings that tells the model to stop generating content if one of the strings is encountered in the response. | \--- |

# **\[page\] Provide tools to the model when accessing the Gemini API through Apple's Foundation Models framework** {#[page]-provide-tools-to-the-model-when-accessing-the-gemini-api-through-apple's-foundation-models-framework}

**Preview**: Accessing the Gemini API through Apple's Foundation Models framework is currently in public preview, which means that it isn't subject to any SLA or deprecation policy and could change in backwards-incompatible ways.  
Also, this integration relies on beta APIs, so apps using it cannot be submitted to the App Store until the next Xcode version reaches General Availability (GA) and supports production submissions.

The examples on this page assume that you've completed the [Get started: Access the Gemini API through Apple's Foundation Models framework](https://firebase.devsite.corp.google.com/docs/ai-logic/apple-foundation-models-framework/get-started).
