import UIKit
import googlemac_iPhone_FirebaseML_NaturalLanguage_Translate_FirebaseMLNLTranslateLib;

class ViewController: UIViewController {
  @IBOutlet var inputTextView: UITextView!
  @IBOutlet var outputTextView: UITextView!

  lazy var translator: Translator = {
    let options = TranslatorOptions(sourceLanguage: "en", targetLanguage: "de")
    return NaturalLanguage.naturalLanguage().translator(options: options)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func onTranslateTap(sender: UIButton) {

    translator.translate(inputTextView.text ?? "") { result, error in
      guard error == nil else {
        self.outputTextView.text = "Failed with error \(error)"
        return;
      }
      self.outputTextView.text = result
    }

}

}

