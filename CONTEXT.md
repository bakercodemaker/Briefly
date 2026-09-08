**Personal news workspace**:
A personal-use product that helps its owner catch up on selected source material, beginning with YouTube videos, while retaining enough transparent product and engineering evidence to serve as a portfolio project.
_Avoid_: A generic content platform, a recruiter-only demo

**Brief**:
A saved, structured and detailed English-language account of one source item, designed to let its owner catch up without watching it. It preserves the source's concrete claims, figures, names, caveats, and reasoning; its full version is accessed from a browsable personal library.
_Avoid_: A generic short news card, a transcript replacement, an unsaved chat response

**Brief preview**:
The compact library representation of a Brief: source title, channel, publication details, and a short extract or key takeaway that helps the owner choose what to open.
_Avoid_: The complete Brief, a clickbait headline

**Source-faithful**:
Constrained to material actually present in the source, with no external fact-checking or added context; attribution and uncertainty expressed by the source are retained.
_Avoid_: An independent news analysis, fabricated certainty

**Personal workspace**:
The private, single-owner area where the owner pastes YouTube URLs and reads their saved Briefs.
_Avoid_: A multi-user SaaS account area

**Language policy**:
The interface is English. Personal Workspace Briefs default to English, and a Brief retains the output language used to create it.
_Avoid_: Translating the interface into two product versions, assuming every Brief is in one language

**On-demand summary flow**:
The primary workspace flow begins with a visible YouTube URL submission. Once analysis completes, the resulting Brief opens in the same session; the saved library is secondary retrieval and history.
_Avoid_: A dashboard that makes the owner search for the create action, a feed-first product

**Brief conversation**:
A future, source-bounded AI conversation about one open Brief. It may produce explicit saved extractions linked to that Brief, such as a list of companies mentioned in an investing video.
_Avoid_: MVP chat, untraceable extracted data, advice beyond the source material

**Immutable generated Brief**:
A completed Brief is retained exactly as generated from its source and selected output language. The owner may archive it or later request regeneration, but cannot edit its contents.
_Avoid_: Mixing owner-authored notes into source-faithful generated output, permanent deletion as the normal removal flow

**Analysis request**:
The owner’s request to create one Brief from one pasted public YouTube URL. It has a visible lifecycle of queued, processing, completed, failed, or cancelled.
_Avoid_: A synchronous page request, a hidden provider call

**Active analysis history**:
The owner’s recent, non-archived Analysis Requests. It opens in a compact three-item view, can expand to a page of ten requests, and pages through older requests.
_Avoid_: An unbounded visible activity feed, the archive

**Archived Brief**:
A completed Brief preserved outside the active personal library after it or its Analysis Request is archived. Archiving either side applies to both: the request leaves active history and the Brief remains available through the archived-briefs area.
_Avoid_: A deleted Brief, a shared public Brief, one-sided removal

**Recoverable failure**:
A temporary provider or quota failure that receives one automatic retry before the owner can choose an explicit manual retry. Invalid or inaccessible source URLs are not recoverable failures.
_Avoid_: Silent failure, endless retrying, treating an invalid URL as temporary

**Brief library**:
The saved collection of completed Briefs, grouped by source channel with newest items first in each group. Each item retains its original URL, source metadata, creation time, output language, lifecycle status, and immutable generated output.
_Avoid_: A topic taxonomy inferred by the model, a search product in the MVP

**Source-and-safety notice**:
A quiet, persistent Brief footer explaining that the Brief was generated from the linked source, may contain errors, and is not verified advice.
_Avoid_: A claim that generated finance, health, political, or other source material has been fact-checked
